function Key =  EM_one_coin_crowd_model(Model, varargin)
% EM algorithm on one-coin model: Assume x_{ij} is the label of worker j giving to item i. z_i is the true label of item i. The one-coin model is
%                                                   prob(x_{ij} = z_i) = p_j,  
%                                                   prob(x_{ij} = c) = (1-p_j)/(Ndom-1) for any c\neq z_i
%                                 where Ndom is the number of possible states of the labels. 
% 
% #prior_worker#: Beta prior on workers' reliabilities (p_j). 
%                 If prior_worker = [alpha, beta], then all the p_j has a prior Beta(alpha, beta) distribution. 
%
% #prior_task#: a Ndom X Ntask matrix that defines the prior knowledge of tasks' labels.   
%
% #partial_truth = {set_index, set_values}#: Fix the labels of items in set_index on set_values. Note partial_truth should be a cell in matlab. 
%
% #maxIter#: number of maximum iterations. 
% 
% #TOL#: error tolerance to terminant. 
%
%
% Qiang Liu @Jan 2013
%%

funcname = mfilename;
[verbose, maxIter, TOL, prior_workers,  prior_tasks, issparse, partial_truth] = process_varargin(varargin, ...
    'verbose', 1, 'maxIter', 100, 'TOL', 1e-3, {'prior_worker', 'ell'}, [], ...
    'prior_task', [], 'issparse', false, 'partial_truth', {[], []});

if issparse, L = sparse(Model.L); else L = full(Model.L); end
Ntask = Model.Ntask; Nwork = Model.Nwork; NeibTask = Model.NeibTask; NeibWork = Model.NeibWork; 
LabelDomain =Model.LabelDomain; Ndom = length(LabelDomain);


partial_dx = partial_truth{1}; partial_array = ones(Model.Ndom, length(partial_dx))/Model.Ndom;
for i = 1:length(partial_dx),     
    partial_array(:, i) = eps; partial_array(partial_truth{2}(i), i) = 1-eps; 
    partial_array(:, i)  = partial_array(:, i) /sum( partial_array(:, i) );
end    
other_dx = setdiff(1:Ntask, partial_dx); other_dx = other_dx(:)';

%% set default prior parameters
if isempty(prior_tasks), prior_tasks = ones(Ndom, Ntask)/Ndom; end
if isempty(prior_workers), prior_workers = ones(2,1);end

%%
mu = zeros(Ndom, Ntask);
% initializing mu
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
reliability = zeros(1, Nwork);
for iter = 1:maxIter
    % updating reliabitity of the workers ...
    for j = 1:Nwork
       neib = NeibWork{j}; labs = L(neib, j)'; 
       pplus = sum(mu((neib-1)*Ndom + labs)); %pminus = length(neib) - pplus;
       reliability(j) = (pplus + prior_workers(1)-1) /  (length(neib) + prior_workers(1) + prior_workers(2)-2);
    end
       
    % updating mu_i(z_i) of the tasks
    old_mu = mu;
    for i = other_dx%1:Ntask
        neib = NeibTask{i}; labs = L(i, neib); reb = reliability(neib); reb = reb(:);
        labs_index = zeros(Ndom,length(neib)); 
        labs_index((0:(length(neib)-1))*Ndom+labs) = 1;        
        logmui = labs_index * log( (reb+eps)./(1-reb+eps) ) + sum(log(1 - reb+eps));
        mu(:, i) = prior_tasks(:,i).* exp(logmui - max(logmui)); mu(:, i) = mu(:, i) / sum(mu(:,i));
    end
    %mu(:, partial_dx) = partial_array;     
    converge_err = max(abs(old_mu(:)-mu(:))); if verbose >= 2, fprintf('%s: %d-th iteration, err=%d\n', funcname, iter, converge_err); end; 
    if converge_err < TOL, break; end      
end

if verbose > 0, fprintf('%s: break at %d-th iteration, converge_err=%d\n', funcname, iter, converge_err); end

% decode the labels of tasks
[~, mxdx] = max(mu.*(1+ rand(size(mu))*eps)); % add some random noise to break ties. 
ans_labels = LabelDomain(mxdx);

% estimate the log marginal probability (used for model selection)
%multi_beta2 = @(x)(prod(gamma(x), 2) ./ gamma(sum(x, 2)));
%logbeta2 = @(x)(sum(gammaln(x), 2) - gammaln(sum(x, 2)));
%logZ = sum(sum(mu.*(log(prior_tasks) - log(mu+eps))))  +  ... 
%sum(sum(logbeta2(alpha),3),1) - Nwork*sum(logbeta2(prior_workers),1);
 
if isfield(Model, 'true_labels') && ~isempty(Model.true_labels)    
    Key.prob_err = mean(ans_labels(:) ~= Model.true_labels(:));   
    if verbose > 0, fprintf('++++++++++++ %s: The error rate is %f ++++++++++\n', funcname, Key.prob_err); end
end

Key.method = funcname;
Key.ans_labels = ans_labels;
Key.reliability = reliability;
Key.mu = mu;
%Key.alpha = alpha;
Key.converge_error = converge_err;
Key.prior_workers = prior_workers;
Key.prior_tasks = prior_tasks;

return;
end





