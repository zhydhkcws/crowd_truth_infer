clear all
addpath(genpath(pwd));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load a simple simulated dataset, 
%  -- L: a matrix where L_ij is the labels of ith task by jth worker, 
%  -- true_labels: the true labels of the tasks. 
load data_simple_demo; 
Model = crowd_model(L); % compile the information into a data structure, 

%% Baseline algorithms
% majority voting
Key_mvote = marjority_vote_crow_model(Model);
prob_error_mvote = mean(Key_mvote.ans_labels ~= true_labels);  
fprintf('Error rate of majority voting: %f\n', prob_error_mvote);
fprintf('+++++++++++++++++++\n');

% EM, two coin model (Dawid & Skene)
options = {'maxIter', 100, 'TOL', 1e-3};%, 'prior_workers', 1.001*ones(2,2)}; 
Key_em =  EM_two_coin_crowd_model(Model, options{:});
prob_error_em = mean(Key_em.ans_labels ~= true_labels);  
fprintf('Error rate of EM two-coin: %f\n', prob_error_em);
fprintf('+++++++++++++++++++\n');

% EM, one coin model 
options = {'maxIter', 100, 'TOL', 1e-3};%, 'prior_workers', 1.001*ones(2,2)}; 
Key_em_1 =  EM_one_coin_crowd_model(Model, options{:});
prob_error_em_1 = mean(Key_em_1.ans_labels ~= true_labels);  
fprintf('Error rate of EM two-coin: %f\n', prob_error_em_1);
fprintf('+++++++++++++++++++\n');

%% BP algorithms
% Belief propagation on one-coin model with Beta(2,1) prior (Liu et al 12)  
options = {'prior', 'beta', 'ell', [2,1], 'maxIter',100, 'TOL', 1e-3};
Key_BP21 = sum_FBP_one_coin_crowd_model(Model, options{:});
prob_error_BP21 = mean(Key_BP21.ans_labels ~= true_labels);  
fprintf('Error rate of BP one coin Beta(2,1): %f\n', prob_error_BP21);
fprintf('+++++++++++++++++++\n');

% Belief propagation on two-coin model with Beta(2,1) & Beta(2,1) prior (Liu et al 12)
options = {'prior', 'beta', 'ell1', [2,1], 'ell2', [2,1],  'maxIter', 100, 'TOL', 1e-3};
Key_BPAB21 = sum_FBP_two_coin_crowd_model(Model, options{:});
prob_error_BPAB21 = mean(Key_BPAB21.ans_labels ~= true_labels);  
fprintf('Error rate of BP two coin Beta(2,1): %f\n', prob_error_BPAB21);
fprintf('+++++++++++++++++++\n');

%% mean field algorithms
% mean field on one-coin model (uniform prior)
Key_MF11 = variationalEM_one_coin_crowd_model(Model, 'ell', [2,1], 'maxIter',100, 'TOL', 1e-3);
prob_error_MF11 = mean(Key_MF11.ans_labels ~= true_labels);  
fprintf('Error rate of mean field one coin: %f\n', prob_error_MF11);
fprintf('+++++++++++++++++++\n');

% mean field on two-coin model (Beta(2,1) prior)
Key_MFAB11 = variationalEM_two_coin_crowd_model(Model, 'ell', [2,1;1,2], 'maxIter',100, 'TOL', 1e-3);
prob_error_MFAB11 = mean(Key_MFAB11.ans_labels ~= true_labels);  
fprintf('Error rate of mean field two coin: %f\n', prob_error_MFAB11);
fprintf('+++++++++++++++++++\n');

%% KOS algorithms in Karger, Oh, Shah. 2011
% this version closely follows the implementation in [KOS]: initializing messages to Norm(1,1), and run only for 10 iterations. 
verbose = 1;
options = {'maxIter',10, 'TOL', 0, 'initialMsg', 'ones+noise', 'verbose', verbose};
Key_kos10 = KOS_method_crowd_model(Model, options{:});
prob_error_kos10 = mean(Key_kos10.ans_labels ~= true_labels);  
fprintf('Error rate of KOS-iteration10: %f\n', prob_error_kos10);
fprintf('+++++++++++++++++++\n');

% KOS again, but with parameters closer to that of BP (initialize to uniform messages (initialMsg='ones') and maxIter=100)
options = {'maxIter',100, 'TOL', 1e-7, 'initialMsg', 'ones', 'verbose', verbose};
Key_kos100 = KOS_method_crowd_model(Model, options{:});
prob_error_kos100 = mean(Key_kos100.ans_labels ~= true_labels);  
fprintf('Error rate of KOS-iteration100: %f\n', prob_error_kos100);
fprintf('+++++++++++++++++++\n');

