function Key =  MinimaxEntropy_Categorical_crowd_model(Model, varargin)
% function Key =  MinimaxEntropy_Categorical_crowd_model(Model, varargin)
% The multiclass minimax conditional entropy algorithm in ICML14 "Aggregating Ordinal Labels from Crowds by Minimax Conditional Entropy". 
%
% varargin: name-value pair arguments in matlab style
%       -- maxIter[default=100]: maximum number of iteration
%       -- TOL[default=1e-3]: error threshold for convergence
%       -- lambda_worker[default=0]: regularization coefficient on the workers
%       -- lambda_task[default-=0]: regularization coefficience on the tasks (items)
%       -- verbose[default=1]: print nothing (verbose=0); print final (verbose=1); print iterative (verbose=2)
% 
% Output: 
%       -- Key.ans_labels: predicted (deterministic) labels for the items
%       -- Key.error_rate: the prediction error rate (if provided with true_labels)
%       -- Key.soft_labels: the predicted soft labels (i.e., the posterior distribution of the item labels)
%       -- Key.parameter_worker: the worker-wise parameters   
%       -- Key.parameter_task: the task-wise parameters
%
% This function used the LBFGS code 'minFunc.m' by Mark Schmidt (http://www.di.ens.fr/~mschmidt/Software/minFunc.html). 
%
% Qiang Liu @Jan 2013
%%

[verbose, maxIter, TOL, prior_workers,  prior_tasks, inner_maxIter, damping, issparse] = process_varargin(varargin, ...
    'verbose', 1, 'maxIter', 100, 'TOL', 1e-3, {'prior_worker', 'ell'}, [], ...
    'prior_task', [],   'inner_maxIter', 1, 'damping', 0, 'issparse', false);
offdiag = process_varargin(varargin,  'offdiag', false);

[lambda_alpha_Vec, lambda_w_Vec] = process_varargin(varargin, 'lambda_worker', 0, 'lambda_task', 0);
[update_alpha, update_w] = process_varargin(varargin,   {'update_parameter_worker'}, true,      {'update_parameter_task'}, true);

if issparse, L = sparse(Model.L); else L = full(Model.L); end    
Ntask = Model.Ntask; Nwork = Model.Nwork; NeibTask = Model.NeibTask; NeibWork = Model.NeibWork;
LabelDomain =Model.LabelDomain; Ndom = length(LabelDomain);

if numel(lambda_alpha_Vec)==1, lambda_alpha_Vec = lambda_alpha_Vec*ones(Nwork,1); end; lambda_alpha_Vec=lambda_alpha_Vec(:);
if numel(lambda_w_Vec)==1, lambda_w_Vec = lambda_w_Vec*ones(Ntask,1); end; lambda_w_Vec=lambda_w_Vec(:);

% set default prior parameters
if isempty(prior_tasks), prior_tasks = ones(Ndom, Ntask)/Ndom; end
if isempty(prior_workers), prior_workers = ones(Ndom, Ndom); end

%%
% set optimization parameters with LBFGS
[maxIter_Mstep, optTOL_Mstep, progTOL_Mstep] = process_varargin(varargin, 'maxIter_Mstep', 25, 'optTOL_Mstep', 1e-3, 'progTOL_Mstep', 1e-3);
options = []; options.bbType = 1;options.Method = 'lbfgs';
options.maxIter = maxIter_Mstep;
options.optTol = optTOL_Mstep;
options.progTOL = progTOL_Mstep;
if verbose >3, options.Display = 'iter'; elseif verbose >2, options.Display = 'final'; else options.Display = 'off'; end


% initializing mu (the posterior prob) using majority voting counting
mu = zeros(2, Ntask);
for i = 1:Ntask
    neib = NeibTask{i}; labs = full(L(i, neib));
    for k = 1:length(LabelDomain)
        mu(k, i) = nnz(labs==LabelDomain(k)) / length(labs);    
    end   
end

wX = zeros(Ndom, Ndom, Ntask); 
alpha = zeros(Ndom, Ndom, Nwork);        
logp_task = zeros(Ndom, Ntask);

cal_truth = false;
if isfield(Model, 'true_labels'), 
    cal_truth = true;
    true_labels = Model.true_labels(:)';
    dx_with_ans = find(isfinite(true_labels));
    prob_err_Vec = zeros(1,maxIter); 
end

%%
% main iteration
err = NaN;
tic
for iter = 1:maxIter    
    % M step
   for inner_iter = 1:inner_maxIter
       % M step: update alpha (confusion matrix)
       if update_alpha
        for j = 1:Nwork
           neib = NeibWork{j}; labs = full(L(neib, j))';
           mu_neibj = mu(:, neib); wX_neibj = wX(:, :, neib); lambda_alpha_v = lambda_alpha_Vec(j);
           obj_handle = @(unknown)obj_update_alpha_minimaxent_per_worker(unknown, wX_neibj, mu_neibj, labs, LabelDomain, lambda_alpha_v, offdiag);       
           alpha_tmp = minFunc(obj_handle, reshape(alpha(:,:,j), [],1), options);           
           alpha(:,:,j) = reshape(alpha_tmp, Ndom, Ndom);
        end 
       end

        % M step: update wx (tasks confusion)
        if update_w
        for i = 1:Ntask
            neib = NeibTask{i}; labs = full(L(i, neib));
            mui = mu(:, i);
            alpha_neibi = alpha(:,:, neib);  lambda_w_v = lambda_w_Vec(i);                
            obj_handle = @(wxi)obj_update_wx_per_task(wxi, mui, alpha_neibi, labs, LabelDomain, lambda_w_v);        
            wX_tmp = minFunc(obj_handle, reshape(wX(:,:,i), [], 1), options);           
            wX(:,:,i) = reshape(wX_tmp, Ndom, Ndom);
        end
        end
   end
    
    % E step: update posterior distribution of the labels (mu)
    old_mu = mu;
    for i = 1:Ntask
        %if nondetermin_flag(i)
            neib = NeibTask{i}; labs = (L(i, neib));
            logp_task(:,i) = log(prior_tasks(:, i));
            for jdx = 1:length(neib)
                j = neib(jdx);
                tmp = alpha(:,:, j) + wX(:,:, i);
                logz = logsumexp2_stable(tmp);
                logp_task(:, i) = logp_task(:, i) + tmp(:, labs(jdx)) - logz;
            end      
            tmp = logp_task(:,i) + damping * log(old_mu(:,i)+eps);
            mu(:,i) = exp(tmp - max(tmp));
            mu(:,i) = mu(:,i)/sum(mu(:,i));
        %end
    end
    
    % check the convergence error 
    err = max(abs(old_mu(:)-mu(:)));
    if verbose >=2, printstr = sprintf('%s: iter=%d, congerr=%f, ', mfilename, iter, err); end
       
    % evaluate ground truth
    if cal_truth
        [~, mxdx] = max(mu.*(1+ rand(size(mu))*eps)); % add some random noise to break ties. 
        ans_labels = LabelDomain(mxdx);
        prob_err_Vec(iter) = mean(ans_labels(dx_with_ans) ~= true_labels(dx_with_ans));
        if verbose >=2, printstr = horzcat(printstr, sprintf('err_rate=%f, ', prob_err_Vec(iter))); end
    end    
    if verbose >=2, printstr = horzcat(printstr, sprintf('time=%f', toc));end
    if verbose >=2, fprintf('%s\n', printstr); end
    
    if err < TOL, break; end                     
end


%% check the error rate

Key.method = mfilename;
[~, mxdx] = max(mu.*(1+ rand(size(mu))*eps)); %decode the labels of tasks: add random noise to break ties. 
Key.ans_labels = LabelDomain(mxdx);
%if cal_truth, Key.error_rate = double(mean(Key.ans_labels ~= true_labels)); end
if isfield(Model, 'true_labels') && ~isempty(Model.true_labels)     
    [Key.error_rate, Key.MoreInfo.error_L1, Key.MoreInfo.error_L2]=cal_error_using_soft_label(mu, Model.true_labels);    
end
Key.soft_labels = mu;
Key.parameter_worker = alpha;
Key.parameter_task = wX;
Key.converge_error = err;

% Print out final information 
% if verbose >= 1 
%      printstr = sprintf('%s:\n\t-- break at %dth iteration, congerr=%f\n', mfilename, iter, err); 
%     if cal_truth, printstr = horzcat(printstr, sprintf('\t-- error rate = %f', Key.error_rate)); end
%      if cal_truth, printstr = sprintf('%s: %f', mfilename, 1 - Key.error_rate); end
%     fprintf('%s\n',printstr);
% end

return;
end


function [obj, Dobj_Dalpha] = obj_update_alpha_minimaxent_per_worker(alpha, wX_neibj, mu_neibj, labs, LabelDomain, lambda, offdiag)

if nargin < 6, lambda = 0; end
if nargin < 7, offdiag=false; end

obj = 0; Ndom = length(LabelDomain); alpha = reshape(alpha, Ndom, Ndom); Dobj_Dalpha = zeros(size(alpha));

for i = 1:size(labs,2)    
    wxi = wX_neibj(:,:, i); 
    MM = wxi + alpha; maxtmp = max(MM, [], 2);  
    expMM = exp( MM - maxtmp(:, ones(1,Ndom)) ); sumexpMM = sum(expMM, 2);
    logz = log(sumexpMM) + maxtmp;            
    obj = obj + (MM(:,labs(i)) - logz)' * mu_neibj(:,i);   
     
    probmatrix = expMM ./ sumexpMM(:, ones(1,Ndom));
    %probmatrix = exp(MM - logz(:, ones(1,Ndom))); %Dobj_Dalpha = Dobj_Dalpha +  mu_neibj(:, i) * (LabelDomain==labs(i)) - diag(mu_neibj(:, i)) * probmatrix';      
    Dobj_Dalpha(:, labs(i)) = Dobj_Dalpha(:, labs(i)) + mu_neibj(:,i);
    Dobj_Dalpha = Dobj_Dalpha - mu_neibj(:,i*ones(1,Ndom)) .* probmatrix;
end

if offdiag
    tmp = diag(diag(alpha));
    obj = -obj + .5 * lambda * (sum(alpha(:).^2) - sum(diag(alpha).^2));
    Dobj_Dalpha = -Dobj_Dalpha(:)  + lambda * (alpha(:) - tmp(:));    
else
    obj = -obj + .5 * lambda * sum(alpha(:).^2);    
    Dobj_Dalpha = -Dobj_Dalpha(:)  + lambda * alpha(:);    
end

return;
end


function [obj, Dobj]= obj_update_wx_per_task(wxi, mui, alpha_neibi, labs, LabelDomain, lambda)

if nargin < 5, lambda = 0; end
Ndom = length(LabelDomain);

wxi = reshape(wxi, Ndom, Ndom);

obj = 0; Dobj_Dw = 0*wxi;
for j = 1:length(labs)    
    MM = wxi + alpha_neibi(:,  :, j); maxtmp = max(MM, [], 2); % w: Nfeature * Ndom        
    expMM = exp(MM-maxtmp(:,ones(1,Ndom))); sumexpMM = sum(expMM, 2);
    logz = log(sumexpMM) + maxtmp;                
    obj = obj + (MM(:, labs(j)) - logz)' * mui;               
        
    %%%        
    probmatrix = expMM ./sumexpMM(:,ones(1,Ndom));        
    Dobj_Dw(:, labs(j)) = Dobj_Dw(:, labs(j)) + mui;
    Dobj_Dw = Dobj_Dw - mui(:,ones(1,Ndom)) .* probmatrix;
end

obj = -obj + 0.5 * lambda * sum(wxi(:).^2);
Dobj = -Dobj_Dw(:) + lambda * wxi(:);

return;
end

