function [result, MoreInfo] = XV_Likelihood_MinimaxEntropy_crowd_model(Model, varargin)
%result = XV_Likelihood_MinimaxEntropy_crowd_model(Model, varargin)
% Select the regularization parameter that maximizes the testing likelihood; see "Aggregating Ordinal Labels from Crowds by Minimax Conditional Entropy, ICML14"
%
% varargin: matlab-style name-value pairs for inputs
%     -- 'Nfold': Number of cross validation partition
%     -- 'algorithm': name of the label aggregation algorithm
%     -- 'lambda_task' and 'lambda_worker': the sets of possible regularization parameters 
%        (default: lambda_worker = 2^[-2:2]*Ndom^2, lambda_task = lambda_worker*[#_tasks_per_worker]/[#_workers_per_task]) 
%    
% outputs:
%     -- result.error_rate: prediction error rate of the algorithm
%     -- result.lambda_worker_selected, result.lambda_task_selected: selected regularization parameters



[Nfold, task_method,verbose] = process_varargin(varargin, 'Nfold',5, 'algorithm', 'full','verbose',1); 

% Default set of regularization parameters
lambda_worker_DEFAULT = 2.^[-2:2] * Model.Ndom^2;
lambda_task_DEFAULT = lambda_worker_DEFAULT * full(mean(Model.DegWork)/mean(Model.DegTask));
[lambda_work_Vec, lambda_task_Vec] = process_varargin(varargin, 'lambda_worker', lambda_worker_DEFAULT, 'lambda_task', lambda_task_DEFAULT);
NlambdaW = length(lambda_work_Vec); NlambdaT = length(lambda_task_Vec); if NlambdaW~=NlambdaT, error('lambda_worker and lambda_task have to have the same length!!'); end

% partition the model for crosss validation
xcross_Model = process_varargin(varargin, {'data_partition', 'xv_model', 'model_partition'}, []);
if isempty(xcross_Model), xcross_Model = xcross_partition_by_workers_crowd_model(Model, Nfold);if verbose>1,fprintf('Create data partition'); end; end
xcross_Model_train = xcross_Model.train; xcross_Model_test = xcross_Model.test; Nfold = length(xcross_Model_train); 

% main loop: 
negloglikelihood = zeros(NlambdaW, Nfold);
for i = 1:NlambdaW
        lambda_c_work = lambda_work_Vec(i); lambda_c_task = lambda_task_Vec(i);
        %parfor kk = 1:Nfold                                
        for kk=1:Nfold
            options = replace_varargin(varargin, 'lambda_task', lambda_c_task, 'lambda_worker', lambda_c_work,'verbose',verbose-2);            
            % run the main algorithm on the training data:
            Key_kk =  MinimaxEntropy_crowd_model(xcross_Model_train{kk}, options{:}); 
            % calculate the liklihood on the test data:
            negloglikelihood(i, kk) = Cal_Likelihood_MinimaxEntropy_crowd_model(xcross_Model_test{kk}, Key_kk, 'algorithm', task_method);                                           
            %Key_Vec{i,kk} = Key_kk;
            if verbose > 1,  fprintf('i=%d, kk=%d, score_kk = %f, time=%f \n', i,  kk, negloglikelihood(i, kk), toc);end
        end
end

% select the best regularization parameter:
meanscores = mean(negloglikelihood,2); bestdx = find(meanscores==min(meanscores));
if numel(bestdx)>1, 
    warning('Ties when selecting parameters; select the strongest regularization');
    [~,dxdx] = max(lambda_work_Vec(bestdx) + lambda_task_Vec(bestdx)); bestdx = bestdx(dxdx); 
end

% run the algorithm on the whole dataset with the selected parameter
options = replace_varargin(varargin, 'lambda_task', lambda_task_Vec(bestdx), 'lambda_worker', lambda_work_Vec(bestdx), 'verbose',verbose-1);        
Key0 =  MinimaxEntropy_crowd_model(Model, options{:});
if isfield(Key0, 'error_rate'), result.error_rate = Key0.error_rate; end
result.lambda_task_selected = lambda_task_Vec(bestdx); 
result.lambda_worker_selected = lambda_work_Vec(bestdx);        
result.lambda_worker_Vec = lambda_work_Vec;
result.lambda_task_Vec = lambda_task_Vec;
result.negloglikelihood_Vec = meanscores(:)';%negloglikelihood;
result.MoreInfo = Key0;
result.MoreInfo.test_negloglikelihood = mean(negloglikelihood,2);
% output more information
if nargout>1, MoreInfo.data_partition = xcross_Model; end
%result.MoreInfo.Key_Vec = Key_Vec;



if verbose>=1
%     fprintf('+++++++++++++++++++++++++++++++++\n')
    fprintf('%s (%s): ', mfilename, task_method);
%     if isfield(result, 'error_rate'),fprintf('\t--Prediction Error Rate = %f\n',result.error_rate);end
     if isfield(result, 'error_rate'),fprintf('%f\n',1 - result.error_rate);end
%     fprintf('\t--Seleted lambdaWorker=%f, lambdaTask=%f via %d-fold Cross validation\n',...
%         result.lambda_worker_selected, result.lambda_task_selected, Nfold);    
%     fprintf('+++++++++++++++++++++++++++++++++\n')    
end

return;
end



