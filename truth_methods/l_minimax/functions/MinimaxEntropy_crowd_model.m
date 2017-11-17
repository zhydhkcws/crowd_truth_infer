function result = MinimaxEntropy_crowd_model(Model, varargin)
% result = MinimaxEntropy_crowd_model(Model, varargin)
% Minimax entropy algorithms for crowdsourcing in "Aggregating Ordinal Labels from Crowds by Minimax Conditional Entropy, ICML'14" 
% and "Learning from the Wisdom of Crowds by Minimax Entropy, NIPS'12"
% 
% varargin: name-value pair arguments in Matlab style
%       -- algorithm[default='categorical']: variants of the algorithms
%             'categorical'-> the categorical minimax entropy algorithm in ICML14
%             'ordinal'-> the ordinal minimax entropy algorithm in ICML14
%             'nips12'-> the eariler algorithm in NIPS14
%       -- maxIter[default=100]: maximum number of iteration
%       -- TOL[default=1e-3]: error threshold for convergence
%       -- lambda_worker[default=0]: regularization coefficient on the workers
%       -- lambda_task[default=0]: regularization coefficience on the tasks (items)
%       -- verbose[default=1]: print nothing (verbose=0); print final (verbose=1); print iterative (verbose=2)
% 
% Outputs: 
%       -- result.ans_labels: predicted (deterministic) labels for the items
%       -- result.error_rate: the prediction error rate (if provided with true_labels)
%       -- result.soft_labels: the predicted soft labels (i.e., the posterior distribution of the item labels)
%       -- result.parameter_worker: the estimated worker-wise model parameters   
%       -- result.parameter_task: the estimated task-wise model parameters
%
% Qiang Liu lqiang67@gmail.com

task_method = process_varargin(varargin, {'algorithm', 'task_method', 'algorithm_type'}, 'categorical');

switch lower(task_method)        
    case {'nip12', 'vector'}
        % Minimax entropy algorithm (the version in NIPS'12) 
        result = MinimaxEntropy_Vector_crowd_model(Model, varargin{:});
                                               
   case {'categorical','full','matrix'}
        % The categorical minimax entropy algorithm in ICML'14       
        result = MinimaxEntropy_Categorical_crowd_model(Model, varargin{:});      
                                             
   case {'ordinal'}
       % The ordinal minimax entropy method in ICML'14. 
        result = MinimaxEntropy_Ordinal_crowd_model(Model, varargin{:});
        
    otherwise
        error('wrong algorithm');
end
    
    