function Key =  DawidSkene_crowd_model(Model, varargin)
% Key =  DawidSkene_crowd_model(Model, varargin)
% The EM algorithm in "Maximum Likelihood Estimation of Observer Error-Rates Using the EM Algorithm, Dawid & Skene 1978".
% varargin: name-value pair arguments in matlab style
%       -- maxIter[default=100]: maximum number of iteration
%       -- TOL[default=1e-3]: error threshold for convergence
%       -- verbose[default=1]: print nothing (verbose=0); print final (verbose=1); print iterative (verbose=2)
% 
% Output: 
%       -- Key.ans_labels: predicted (deterministic) labels for the items
%       -- Key.error_rate: the prediction error rate (if provided with true_labels)
%       -- Key.soft_labels: the predicted soft labels (i.e., the posterior distribution of the item labels)
%       -- Key.parameter_worker: the worker-wise parameters (the workers' confusion matrices)
%
%
% Qiang Liu @Jan 2013
%%

[verbose, maxIter, TOL, prior_workers,  prior_tasks, issparse, partial_truth] = process_varargin(varargin, ...
    'verbose', 1, 'maxIter', 100, 'TOL', 1e-3, {'prior_worker', 'ell'}, [], ...
    'prior_task', [], 'issparse', false, 'partial_truth', {[], []});

if issparse, L = sparse(Model.L); else L = full(Model.L); end
Ntask = Model.Ntask; Nwork = Model.Nwork; NeibTask = Model.NeibTask; NeibWork = Model.NeibWork;
LabelDomain =Model.LabelDomain; Ndom = length(LabelDomain);

partial_dx = partial_truth{1};
partial_array = ones(Model.Ndom, length(partial_dx))/Model.Ndom;
for i = 1:length(partial_dx),     
    partial_array(:, i) = eps; partial_array(partial_truth{2}(i), i) = 1-eps; 
    partial_array(:, i)  = partial_array(:, i) /sum( partial_array(:, i) );
end    
other_dx = setdiff(1:Ntask, partial_dx); other_dx = other_dx(:)';

% set default prior parameters
if isempty(prior_tasks), prior_tasks = ones(Ndom, Ntask)/Ndom; end
if isempty(prior_workers), prior_workers = ones(Ndom, Ndom); end

%%
alpha = ones(Ndom, Ndom, Nwork); mu = zeros(Ndom, Ntask);
% initializing mu using frequency counts
for i = 1:Ntask
    neib = NeibTask{i}; labs = L(i, neib);
    for k = 1:length(LabelDomain)
        mu(k, i) = prior_tasks(k,i).* nnz(labs==LabelDomain(k)) / length(labs);                    
    end   
    mu(:, i) = mu(:, i)/sum(mu(:, i));
end
mu(:, partial_dx) = partial_array;

%%
% main iteration
err = NaN;
for iter = 1:maxIter
    % M-Step: Updating workers' confusion matrix (alpha)
    for j = 1:Nwork
       neib = NeibWork{j}; labs = L(neib, j)'; 
       alpha(:, :, j) = prior_workers - 1 + eps;
       for ell = 1:Ndom
           dx = neib(labs == LabelDomain(ell));
           alpha(:, ell, j) = alpha(:, ell, j) + sum(mu(:, dx),2);
       end
    end
    alpha  = alpha./repmat(sum(alpha, 2), [1, Ndom, 1]);
    
    % E-Step: Updating tasks' posterior probabilities (mu)
    old_mu = mu;
    for i = other_dx%1:Ntask
        neib = NeibTask{i}; labs = L(i, neib);
        tmp = 0;   
        for ell = 1:Ndom
            jdx = neib(labs == LabelDomain(ell));
            tmp = tmp + sum(log(alpha(:, ell, jdx)), 3);
        end
	    mu(:, i) = prior_tasks(:,i) .* exp(tmp - max(tmp));         
        mu(:, i) = mu(:, i) / sum(mu(:,i));
    end     
    err = double(max(abs(old_mu(:)-mu(:))));
    if verbose >= 2, fprintf('%s: %d-th iteration, converge error=%d\n', mfilename, iter, err); end; if err < TOL, break; end      
end


% decode the labels of tasks
[~, mxdx] = max(mu.*(1+ rand(size(mu))*eps)); % add some random noise to break ties. 
ans_labels = LabelDomain(mxdx);

%Key = Model;
Key.method = mfilename; %'EM_crowd_model (Dawid&Skene, two coin model)';
Key.ans_labels = ans_labels;
if isfield(Model, 'true_labels') && ~isempty(Model.true_labels)    
    %dxdx = isfinite(Model.true_labels);
    %true_labels = Model.true_labels(:)';
    %Key.error_rate = double(mean(ans_labels(dxdx) ~= true_labels(dxdx)));    
    [Key.error_rate, Key.MoreInfo.error_L1, Key.MoreInfo.error_L2]=cal_error_using_soft_label(mu, Model.true_labels);    
end
Key.soft_labels = mu;
Key.parameter_worker = alpha;
Key.converge_error = double(err);

% Print out final information 
if verbose >= 1 
%     printstr = sprintf('%s:\n\t-- break at %dth iteration, congerr=%f\n', mfilename, iter, err); 
%     if isfield(Key, 'error_rate'), printstr = horzcat(printstr, sprintf('\t-- error rate = %f', Key.error_rate)); end
    if isfield(Key, 'error_rate'), printstr = sprintf('%s:\t-- accu rate = %f', mfilename, 1 - Key.error_rate); end
    fprintf('%s\n',printstr);
end


return;
end





