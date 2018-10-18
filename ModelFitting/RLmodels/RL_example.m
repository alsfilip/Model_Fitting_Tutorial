%% 0) MODEL FITTING TUTORIAL - SASQUATCH 10/18/2018
%
% Refer any questions to Alex Filipowicz, email: alsfilip@gmail.com

% This tutorial is meant as an introduction to methods for fitting an
% comparing computational models. The following is an example of using
% log-likelihood estimates to fit popular reinforcement learning models.
% What is presented here covers the first part of the methods presented in:
%
% Trial-by-trial analysis using computational models (2011) Nathaniel Daw, Decision making, affect, and learning: Attention and performance XXIII 
%
%==========================================================================
close all;
clear all;
clear clc;

rng(100); %Set random seed

%% 1) EXAMPLE 1: 2-ARM BANDIT TASK WITH STATIC PROBABILITY

% The first example covers a pretty common type of task in learning and
% decision-making: a two-armed bandit task. The subject chooses between
% two options (for the sake of this example, a slot machine on the left and
% on the right) that each have a probability of giving a reward. The
% subject's goal is to maximize reward by using the task feedback to learn
% which slot machine gives the highest probability of giving a reward.
%
% In this example, the left slot machine has a 70% chance of giving a
% payout, and the right slot machine gives a 30% chance. The code below
% generates the task parameters.
%
%==========================================================================
%% 1.1) GENERATE TASK PARAMETERS
% Create reward Matrix - this matrix determines on which trials the slot
% machines give a reward if selected

p = .9;              %Probability of getting a reward from first slot machine
rewProb = [p 1-p];   %Setting the probability of the second slot machine to 1-prob first slot machine
ntrials = 100;      %Total number of trials

%Reward matrix
rew = rand(ntrials,2);            %Generate random numbers between 0 and 1
rew(rew(:,1) < rewProb(1),1) = 1; %Identify the trials that will be rewarded for the first slot machine
rew(rew(:,2) < rewProb(2),2) = 1; %Do the same for the second slot machine
rew(rew ~= 1) = 0;                %Set all other trials to 0 reward

%% 1.2) MODELING BEHAVIOR

% This type of task is well modeled by a popular class of computational
% models called "reinforcement learning" models (Sutton & Barto, 1998,
% Reinforcement Learning: An introduction)
%
% These models learn by keeping track of the "value" for different options in
% the environment - in our case, the difference in the value the model
% attributes to the different slots.
%
% In its most basic form, the values (V) for each option (i) on any trial
% (t) are given by the Rescorla-Wagner learning rule:
%
% Vt+1(i) = Vt(i)+alpha*delta
%
% where delta is the prediction error (i.e., the amount of reward expected
% vs the amount received), and alpha is a free parameter that determines
% how much the model learns from the prediction error (known as a "learning
% rate" parameter). When alpha tends towards 0, the model updates its
% values very slowly whereas when alpha tends towards 1 the model updates
% more rapidly.
%
% If going purely by these values, the model would select whichever option
% is more valuable on each trial. However, humans tend to be more
% stochastic when making decisions. This type of behavior is commonly
% captured using a softmax action selection policy, which transforms values
% into the probability that any action will be selected. This policy takes
% the form:
%
% Pr(choice i on trial t) = exp(beta x Vt(i))/sum(exp(beta x Vt(all options))
%
% where Pr(choice i) is the probability that option i will be selected on
% any trial t, Vt(i) is the current value of option i, and beta is a free
% inverse temperature parameter that scales the "greediness" of the model.
% When beta tends towards 0, choices are made randomly, regardless of the
% value of each option; when beta tends towards infinity the option with
% the highest value is chosen more consistently (also known as a hard-max
% policy).
%
% An property of the softmax function is that it's influence depends on the
% relative difference in value between the options. When the difference in
% value is small, participants choose more stochastically, whereas when the
% difference is large, participants choose more deterministically. The code
% below shows examples of how the probability of choosing an option changes
% as a function of the relative difference between two options. This
% difference is shown for difference values of beta:

Va = .01:.01:.99;
Vb = 1-Va;
betas = [.5 1 2 3 5 10 20];
figure(1)
hold on;
for i=1:length(betas)
    disp(i)
    PrA = zeros(length(Va),1);
    for i2=1:length(Va)
        disp(i2)
        PrA(i2) = exp(betas(i)*Va(i2))/(exp(betas(i)*Va(i2))+exp(betas(i)*Vb(i2)));
    end
    plot(Va-Vb,PrA,'-','LineWidth',2)
end
xlabel('Value for Option A - Value for Option B')
ylabel('Probability of choosing Option A')
ylim([0,1])
lgd = legend({'.5','1','2','3','5','10','20'},'Location','southeast')
title(lgd,'Beta')

%==========================================================================
%% 1.2.1) SIMPLE RL MODEL
%
% Let's see how a simple RL model with the specifications listed above
% behaves in our learning task environment. The model can be found by
% opening "RL_alpha.m"
%
% The following runs a model with the alpha parameter set to .25 and the
% beta parameter set to 3
alpha = .25;
beta = 3;
data = RL_alpha(rew,alpha,beta); %Function to simulate RL behavior

% Plot the behavior - the first column plots the model's behavior with the
% parameters above
figure(2)
subplot(2,3,1)
hold on;
plot([0 ntrials],[p p],'--b','LineWidth',2)
plot([0 ntrials],[1-p 1-p],'--r','LineWidth',2)
plot(data.Pchoice(:,1),'-b')
plot(data.Pchoice(:,2),'-r')
plot([0,ntrials],[.5,.5],'--k')
title(sprintf('Alpha = %d, Beta = %d',round(alpha,2),round(beta,2)))
xlabel('Trial')
ylabel('Choice Probability')

subplot(2,3,4)
hold on;
plot([0 ntrials],[p p],'--b','LineWidth',2)
plot([0 ntrials],[1-p 1-p],'--r','LineWidth',2)
plot(data.QValues(:,1),'-b')
plot(data.QValues(:,2),'-r')
xlabel('Trial')
ylabel('Q-Values')

%% What happens when we change Beta?
alpha = .25;
beta = 1;
data2 = RL_alpha(rew,alpha,beta); %Function to simulate RL behavior

subplot(2,3,2)
hold on;
plot([0 ntrials],[p p],'--b','LineWidth',2)
plot([0 ntrials],[1-p 1-p],'--r','LineWidth',2)
plot(data2.Pchoice(:,1),'-b')
plot(data2.Pchoice(:,2),'-r')
plot([0,ntrials],[.5,.5],'--k')
ylim([0,1])
title(sprintf('Alpha = %d, Beta = %d',round(alpha,2),round(beta,2)))
xlabel('Trial')
ylabel('Choice Probability')

subplot(2,3,5)
hold on;
plot([0 ntrials],[p p],'--b','LineWidth',2)
plot([0 ntrials],[1-p 1-p],'--r','LineWidth',2)
plot(data2.QValues(:,1),'-b')
plot(data2.QValues(:,2),'-r')
xlabel('Trial')
ylabel('Q-Values')

%% What happens when we change Alpha?
alpha = .7;
beta = 3;
data3 = RL_alpha(rew,alpha,beta); %Function to simulate RL behavior

subplot(2,3,3)
hold on;
plot([0 ntrials],[p p],'--b','LineWidth',2)
plot([0 ntrials],[1-p 1-p],'--r','LineWidth',2)
plot(data3.Pchoice(:,1),'-b')
plot(data3.Pchoice(:,2),'-r')
plot([0,ntrials],[.5,.5],'--k')
ylim([0,1])
title(sprintf('Alpha = %d, Beta = %d',round(alpha,2),round(beta,2)))
xlabel('Trial')
ylabel('Choice Probability')

subplot(2,3,6)
hold on;
plot([0 ntrials],[p p],'--b','LineWidth',2)
plot([0 ntrials],[1-p 1-p],'--r','LineWidth',2)
plot(data3.QValues(:,1),'-b')
plot(data3.QValues(:,2),'-r')
xlabel('Trial')
ylabel('Q-Values')

%==========================================================================
%% 1.2.2) FITTING SUBJECT PERFORMANCE
%
% Now that we have a model of behavior, let's explore model fitting
% methods. Fitting generally uses methods to search a bunch of parameter
% values and finds the ones that match participant behavior most closely.
%
% Common algorithms define some kind of "loss function", a criterion that
% allows you to measure how much models using different parameter sets
% deviate from participant performance (the goal being to minimize this
% deviation). Once a loss function has been defined, gradient decent
% algorithms can be run to try and find the set of parameters that find the
% lowest point on a loss function.
%
% A common loss function is the negative log-likelihood. The likelihood
% specifies the probability of the observed data (in our case, participant
% choices) given the model parameters. We can either maximize the
% log-likelihood, or minimize the negative log-likelihood. MATLAB provides
% some convenient tools for the latter, so this will be what I will use
% below.
%
% Open up the "RL_alpha_LL.m" script to see how the negative log likelihood
% is being computed. The likelihood is the product of the probability that
% the model would have made the same choice as the participant on every
% trial. Given that multiplying probabilies will quickly produce very small
% numbers, we generally sum the log-likelihood to get a number that is
% easier to work with.
%
% Here is a visual example of what the loss function looks like. Below I've run three simulations with the same
% beta but three different values of alpha. Next I plot the negative
% log-likelihood computed by running different simulations with a range of
% different alphas - note here that the smaller the number, the better the
% fit.

% Make new reward matrix
ntrials = 1000;      %Total number of trials

rng(102)
%Reward matrix
rew = rand(ntrials,2);            %Generate random numbers between 0 and 1
rew(rew(:,1) < rewProb(1),1) = 1; %Identify the trials that will be rewarded for the first slot machine
rew(rew(:,2) < rewProb(2),2) = 1; %Do the same for the second slot machine
rew(rew ~= 1) = 0; 

% Run 3 simulated participants
data1 = RL_alpha(rew,.1,3); %Simulated choices using alpha = .1, beta = 3
data2 = RL_alpha(rew,.5,3); %Simulated choices using alpha = .5, beta = 3
data3 = RL_alpha(rew,.9,3); %Simulated choices using alpha = .9, beta = 3

% Compute negative log-likelihood for a range of values of alpha
alphas = .01:.01:1;
nlls = zeros(length(alphas),3);
for i=1:length(alphas)
    nlls(i,1)= RL_alpha_LL(rew,alphas(i),3,data1.Choices);
    nlls(i,2)= RL_alpha_LL(rew,alphas(i),3,data2.Choices);
    nlls(i,3)= RL_alpha_LL(rew,alphas(i),3,data3.Choices);
end

figure(3)
subplot(1,3,1)
hold on;
plot(alphas,nlls(:,1),'-k','Linewidth',2)
plot([.1 .1],[260 440],'--r','Linewidth',1)
ylabel('Negative Log-Likelihood')
xlabel('Alphas')
title('Alpha = .1')

subplot(1,3,2)
hold on;
plot(alphas,nlls(:,2),'-k','Linewidth',2)
plot([.5 .5],[280 380],'--r','Linewidth',1)
xlabel('Alphas')
title('Alpha = .5')

subplot(1,3,3)
hold on;
plot(alphas,nlls(:,3),'-k','Linewidth',2)
plot([.9 .9],[300 440],'--r','Linewidth',1)
xlabel('Alphas')
title('Alpha = .9')

%==========================================================================
%% 1.2.3) FIT SIMULATION
%
% When there is a large parameter space to fit, it is generally good to use
% optimization algorithms. I like to use the Multistart function, which
% initiates a bunch of random searches in parameter space in parallel using
% the fmincon function. While not perfect, it definitely helps get around
% bumpy likelihood functions.
%
% Check the "fit_RL_alpha.m" function to see how this is implemented. Here
% we're going to try and fit a few different parameter sets. If our fitting
% is working correctly, we should see that our fits should match the
% parameters we input into our simulations. Based on the plots below, we
% can see that this is the case.

rng(106);
rew = rand(ntrials,2);            %Generate random numbers between 0 and 1
rew(rew(:,1) < rewProb(1),1) = 1; %Identify the trials that will be rewarded for the first slot machine
rew(rew(:,2) < rewProb(2),2) = 1; %Do the same for the second slot machine
rew(rew ~= 1) = 0;

data1 = RL_alpha(rew,.1,5); %Simulated choices using alpha = .1, beta = 5
data2 = RL_alpha(rew,.2,3); %Simulated choices using alpha = .5, beta = 3
data3 = RL_alpha(rew,.5,2); %Simulated choices using alpha = .9, beta = 1
data4 = RL_alpha(rew,.7,1); %Simulated choices using alpha = .9, beta = 1
data5 = RL_alpha(rew,.9,.5); %Simulated choices using alpha = .9, beta = 1

params1 = fit_RL_alpha(rew,data1.Choices);
params2 = fit_RL_alpha(rew,data2.Choices);
params3 = fit_RL_alpha(rew,data3.Choices);
params4 = fit_RL_alpha(rew,data4.Choices);
params5 = fit_RL_alpha(rew,data5.Choices);

figure(4)
subplot(1,2,1)
hold on;
plot([.1 .2 .5 .7 .9],[params1(1) params2(1) params3(1) params4(1) params5(1)],'ok')
plot([0 1],[0 1],'--k')
xlabel('Actual Alpha')
ylabel('Recovered Alpha')
title('Alpha')

subplot(1,2,2)
hold on;
plot([5 3 2 1 .5],[params1(2) params2(2) params3(2) params4(2) params5(2)],'ok')
plot([0 5],[0 5],'--k')
xlabel('Actual Beta')
ylabel('Recovered Beta')
title('Beta')

%==========================================================================
%% 1.3) COMPARING MODELS
%
% The statistician George Box has been