function negloglike = Cal_Likelihood_MinimaxEntropy_crowd_model(Model, Key_alg, varargin)
% negloglike = Cal_Likelihood_MinimaxEntropy_crowd_model(Model, Key_alg, varargin)
% Calculate the negative log-likelihood for the models outputed by MinimaxEntropy_crowd_model.m

task_method = process_varargin(varargin, {'algorithm','task_method', 'algorithm_type'}, 'row');

switch lower(task_method)        
    case {'vector', 'nips12'} % the version in NIPS'12
        [negloglike]  = Cal_Likelihood_MinimaxEntropy_Vector_crowd_model(Model, Key_alg);
        
   case {'nip12-to-onecoin','vector-to-onecoin'}
        [negloglike]  = Cal_Likelihood_MinimaxEntropy_Vector_crowd_model(Model, Key_alg);               
       
    case {'categorical', 'full'} % the categorical method in ICML'14
        [negloglike]  = Cal_Likelihood_MinimaxEntropy_Categorical_crowd_model(Model, Key_alg);      
        
   case {'categorical-to-onecoin','full-to-onecoin','matrix-to-onecoin'} 
       % same as full, but use a regularization that penalizes towards one-coin model. 
        [negloglike]  = Cal_Likelihood_MinimaxEntropy_Categorical_crowd_model(Model, Key_alg);                     
        
    case {'ordinal','ordinal-double', 'ordinal_double'} %ordinal minimax in ICML'14
        [negloglike]  = Cal_Likelihood_MinimaxEntropy_Ordinal_crowd_model(Model, Key_alg);              
        
    otherwise
        error('wrong algorithm');
end
    
    