clear all; addpath(genpath(pwd));

load toy_data; 
Model = crowd_model(L, 'true_labels',true_labels);

%%
% Majority voting: 
% mv = MajorityVote_crowd_model(Model);

% Dawid & Sknene: 
% ds = DawidSkene_crowd_model(Model);


%%
% Set parameters:
lambda_worker = 0.25*Model.Ndom^2; lambda_task = lambda_worker * (mean(Model.DegWork)/mean(Model.DegTask)); % regularization parameters
opts={'lambda_worker', lambda_worker, 'lambda_task', lambda_task, 'maxIter',50,'TOL',5*1e-3','verbose',1};
% 1. Categorical minimax entropy:
result1 =  MinimaxEntropy_crowd_model(Model,'algorithm','categorical',opts{:});
% 2. Ordinal minimax entropy: 
result2 =  MinimaxEntropy_crowd_model(Model,'algorithm','ordinal',opts{:});

%%
% Select regularization parameters that maximizes the testing loglikelihood (can be SLOW!!)
lambda_worker = 2.^[-2:2]*Model.Ndom^2; lambda_task = lambda_worker * (mean(Model.DegWork)/mean(Model.DegTask)); % potential parameter set
Nfold = 5; %Number of the cross validation partition
opts = {'maxIter', 50, 'TOL', 5*1e-3,'verbose',1}; fprintf('\n\n');
resultxv1=XV_Likelihood_MinimaxEntropy_crowd_model(Model,  'algorithm', 'categorical', opts{:});
resultxv2=XV_Likelihood_MinimaxEntropy_crowd_model(Model, 'algorithm', 'ordinal', opts{:}); 


exit