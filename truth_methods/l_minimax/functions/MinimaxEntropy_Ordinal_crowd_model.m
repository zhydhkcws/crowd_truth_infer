function Key =  MinimaxEntropy_Ordinal_crowd_model(Model, varargin)
% function Key =  MinimaxEntropy_Ordinal_crowd_model(Model, varargin)
% The ordinal minimax conditional entropy algorithm in ICML14 "Aggregating Ordinal Labels from Crowds by Minimax Conditional Entropy". 
%
% varargin: name-value pair arguments in matlab style
%       -- maxIter[default=100]: maximum number of iteration
%       -- TOL[default=1e-3]: error threshold for convergence
%       -- lambda_worker[default=0]: regularization coefficient on the workers
%       -- lambda_task[default=0]: regularization coefficience on the tasks (items)
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
% Qiang Liu @Sep 2013
%%

[verbose, maxIter, TOL, prior_workers,  prior_tasks] = process_varargin(varargin,'verbose', 1, 'maxIter', 100, 'TOL', 1e-3, {'prior_worker', 'ell'}, [], 'prior_task', []);
[lambda_xx_work, lambda_xx_task] = process_varargin(varargin, 'lambda_worker', 0, 'lambda_task', 0);
[issparse, update_xx_task, update_xx_work] = process_varargin(varargin, 'issparse', false, 'update_parameter_task', true, 'update_parameter_worker', true);
if issparse, L = sparse(Model.L); else L = full(Model.L); end
Ntask = Model.Ntask;Nwork = Model.Nwork;NeibTask = Model.NeibTask;NeibWork = Model.NeibWork;LabelDomain =Model.LabelDomain;Ndom = length(LabelDomain);

% set default prior parameters
if isempty(prior_tasks), prior_tasks = ones(Ndom, Ntask)/Ndom; end 
if isempty(prior_workers), prior_workers = ones(Ndom, Ndom); end

% set up optimization (LBFGS) parameters 
[maxIter_Mstep, optTOL_Mstep, progTOL_Mstep] = process_varargin(varargin, 'maxIter_Mstep', 25, 'optTOL_Mstep', 1e-3, 'progTOL_Mstep', 1e-3);
options = []; options.bbType = 1;options.Method = 'lbfgs'; 
options.maxIter = maxIter_Mstep; options.optTol = optTOL_Mstep; options.progTOL = progTOL_Mstep;
if verbose >=5, options.Display = 'iter'; elseif verbose >=3, options.Display = 'final'; else options.Display = 'off'; end 

%%
logp_task = zeros(Ndom, Ntask); mu = zeros(2, Ntask); 

% initializing mu using majority vote
for i = 1:Ntask
    neib = NeibTask{i}; labs = full(L(i, neib));
    for k = 1:length(LabelDomain)
        mu(k, i) = nnz(labs==LabelDomain(k)) / length(labs);    
    end        
end

BB = construct_sufficient_statistics_ordinalminimaxent(Ndom); Nbb = size(BB,3);
[xx_work, xx_task] = process_varargin(varargin, 'initial_parameter_worker', zeros(Nbb, Nwork), 'initial_parameter_task', zeros(Nbb, Ntask));


%% main iteration

err = NaN;
tic
for iter = 1:maxIter    
   % M step: update alpha (confusion matrix)
   if update_xx_work
    for j = 1:Nwork
       neib = NeibWork{j}; labs = (L(neib, j))';
       obj_handle = @(unknown)update_per_worker_v2(xx_task(:, neib), unknown, mu(:, neib), labs, BB, lambda_xx_work);%, offdiag);
       xx_work(:, j) = minFunc(obj_handle,  xx_work(:, j), options);           
    end 
   end
   
   %  M step: update wx (tasks confusion)
   if update_xx_task
    for i = 1:Ntask
        neib = NeibTask{i}; labs = (L(i, neib));
        obj_handle = @(unknown)update_per_task_v2(unknown, xx_work(:, neib), mu(:, i), labs, BB, lambda_xx_task);        
        xx_task(:, i) = minFunc(obj_handle, xx_task(:, i), options);           
    end
   end
                   
    % E step: update mu (task truth)
    old_mu = mu;
    for i = 1:Ntask
            neib = NeibTask{i}; labs = (L(i, neib));
            logp_task(:,i) = log(prior_tasks(:, i));
            for jdx = 1:length(neib)
                j = neib(jdx);
                tmp = weighted_sum_matrix3(BB, xx_work(:,j)) + weighted_sum_matrix3(BB, xx_task(:, i));
                logz = logsumexp2_stable(tmp);
                logp_task(:, i) = logp_task(:, i) + tmp(:, labs(jdx)) - logz;

            end       
            mu(:,i) = exp(logp_task(:,i) - max(logp_task(:,i) ));
            mu(:,i) = mu(:,i)/sum(mu(:,i));
    end

    err = max(abs(old_mu(:)-mu(:)));
    if verbose >= 2, fprintf('%s: iter=%d, congerr=%f, time=%f\n', mfilename, iter, err, toc); end
    if err < TOL, break; end    
end

% decode the labels of tasks
[~, mxdx] = max(mu.*(1+ rand(size(mu))*eps)); % add some random noise to break ties. 
ans_labels = LabelDomain(mxdx);
 
Key.method = mfilename;
Key.ans_labels = ans_labels;
if isfield(Model,'true_labels') && ~isempty(Model.true_labels)
    %dx = isfinite(Model.true_labels);
    %alab = Key.ans_labels(:)'; tlab =Model.true_labels(:)';
    %Key.error_rate = double(mean(alab(dx) ~= tlab(dx))); 
    [Key.error_rate, Key.MoreInfo.error_L1, Key.MoreInfo.error_L2]=cal_error_using_soft_label(mu, Model.true_labels);    
end
Key.soft_labels = mu;
Key.parameter_worker = xx_work;
Key.parameter_task = xx_task;
Key.converge_error = err;

if verbose >= 1 
%     printstr = sprintf('%s:\n\t-- break at %dth iteration, congerr=%f\n', mfilename, iter, err); 
%     if isfield(Key,'error_rate'), printstr = horzcat(printstr, sprintf('\t-- error rate = %f', Key.error_rate)); end
     if isfield(Key,'error_rate'), printstr = sprintf('%s: %f', mfilename, 1 - Key.error_rate); end
     fprintf('%s\n',printstr);
end

return;
end


function [obj, dobj] = update_per_worker_v2(xx_task, xx_work, mu, labs, BB, lambda)

j = 1;
Nbb = size(BB, 3); Ndom = size(mu,1);
obj = 0; dobj = zeros(size(xx_work));
for i = 1:length(labs)
    MM = weighted_sum_matrix3(BB, xx_work(:, j))  + weighted_sum_matrix3(BB, xx_task(:, i));  
    logz = logsumexp2_stable(MM); logalpha = MM - logz * ones(1,Ndom); % calculate logp

    obj = obj + mu(:, i)' * logalpha(:, labs(i)); 
    dobj = dobj +  squeeze(BB(:, labs(i), :))' * mu(:, i)  -  squeeze(sum(exp(logalpha(:,:,ones(1,Nbb))) .* BB, 2))'*mu(:,i);
end

obj = -obj + .5*lambda*(sum(xx_work.^2));
dobj = -dobj + lambda*xx_work;

return;
end


function [obj, dobj] = update_per_task_v2(xx_task, xx_work, mu, labs, BB, lambda)

i = 1; 
Nbb = size(BB, 3); 
Ndom = size(mu,1);
obj = 0; dobj = zeros(size(xx_task));
for j = 1:length(labs)
    MM = weighted_sum_matrix3(BB, xx_work(:, j)) + weighted_sum_matrix3(BB, xx_task(:, i)); 
    logz = logsumexp2_stable(MM); logalpha = MM - logz * ones(1,Ndom);

    obj = obj + mu(:, i)' * logalpha(:, labs(j));
    dobj = dobj +  squeeze(BB(:, labs(j), :))' * mu(:, i)  -  squeeze(sum(exp(logalpha(:,:,ones(1,Nbb))) .* BB, 2))'*mu(:,i);
    
end
obj = -obj + .5*lambda*sum(xx_task.^2);
dobj = -dobj + lambda*xx_task;

return;
end


function MM = weighted_sum_matrix3(BB, xx)

Ndom = size(BB,1);
MM = sum(BB .* permute(xx(:, ones(Ndom,1), ones(Ndom,1)), [3,2,1]), 3);

return;
end

function logz = logsumexp2_stable(tmp)
            
maxtmp = max(tmp, [], 2);
logz = log(sum(exp(tmp - maxtmp(:, ones(1,size(tmp,2)))), 2)) + maxtmp;  %logz = log(sum(exp(tmp - repmat(maxtmp, Ndom, 1)), 1)) + maxtmp;           

return;
end

