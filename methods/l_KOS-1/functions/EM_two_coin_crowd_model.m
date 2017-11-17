function Key =  EM_two_coin_crowd_model(Model, varargin)
% EM algorithm on two coin model (Dawid & Skene 1979): Assume x_{ij} is the label of item i given by worker j. z_i is the true label of item i. 
%                                                      The model assumes: 
%                                                                 prob(x_{ij} = c | z_i = k) = A_{j,ck}
%                                                      where A_j = {A_{j,ck}} a confusion matrix of worker j.
% varargin: 
%       prior_worker (or ell): the alpha parameters of Dirichlet prior of the workers' reliabilities. It has to be a Ndom X Ndom matrix.
%       prior_task: the prior knowledge of tasks' labels. 
%       maxIter: maximum number of iteration
%       TOL: error tolerance       
%       verbose: control output information. 
%
% Qiang Liu @Jan 2013. There are some problem when using partial_truth; use prior_task instead
%%

funcname = mfilename;
[verbose, maxIter, TOL, prior_workers,  prior_tasks,  returnMore, damping, issparse, partial_truth] = process_varargin(varargin, ...
    'verbose', 1, 'maxIter', 100, 'TOL', 1e-3, {'prior_worker', 'ell'}, [], ...
    'prior_task', [], 'returnMore', 0, 'damping', 0, 'issparse', false, 'partial_truth', {[], []});

if issparse
    L = sparse(Model.L);
else
    L = full(Model.L);
end
Ntask = Model.Ntask;
Nwork = Model.Nwork;
NeibTask = Model.NeibTask;
NeibWork = Model.NeibWork;
LabelDomain =Model.LabelDomain;
Ndom = length(LabelDomain);


partial_dx = partial_truth{1};
partial_array = ones(Model.Ndom, length(partial_dx))/Model.Ndom;
for i = 1:length(partial_dx),     
    partial_array(:, i) = eps; partial_array(partial_truth{2}(i), i) = 1-eps; 
    partial_array(:, i)  = partial_array(:, i) /sum( partial_array(:, i) );
end    
other_dx = setdiff(1:Ntask, partial_dx); other_dx = other_dx(:)';

%% set default prior parameters
if isempty(prior_tasks)
    prior_tasks = ones(Ndom, Ntask)/Ndom;
end

if isempty(prior_workers)
    prior_workers = ones(Ndom, Ndom);
end

%%
alpha = ones(Ndom, Ndom, Nwork);
mu = zeros(Ndom, Ntask);
% initializing mu
for i = 1:Ntask
    neib = NeibTask{i}; labs = L(i, neib);
    for k = 1:length(LabelDomain)
        %mu(k, i) = nnz(labs==LabelDomain(k)) / length(labs);    
        mu(k, i) = prior_tasks(k,i).* nnz(labs==LabelDomain(k)) / length(labs);                    
    end   
    mu(:, i) = mu(:, i)/sum(mu(:, i));
end
mu(:, partial_dx) = partial_array;

%%
% main iteration
err = NaN;
for iter = 1:maxIter
    % updating Beta distributions (of the workers) ...
    for j = 1:Nwork
       neib = NeibWork{j}; labs = L(neib, j)'; 
       alpha(:, :, j) = prior_workers - 1 + eps;
       for ell = 1:Ndom
           dx = neib(labs == LabelDomain(ell));
           alpha(:, ell, j) = alpha(:, ell, j) + sum(mu(:, dx),2);
       end
    end
    alpha  = alpha./repmat(sum(alpha, 2), [1, Ndom, 1]);
    
    % updating mu_i(z_i) of the tasks
    old_mu = mu;
    for i = other_dx%1:Ntask
        neib = NeibTask{i}; labs = L(i, neib);
        tmp = 0;%-sum(log(sum(alpha(:, :, neib),2)),3);        
        for ell = 1:Ndom
            jdx = neib(labs == LabelDomain(ell));
            tmp = tmp + sum(log(alpha(:, ell, jdx)), 3);
        end        
	if damping == 0
	        mu(:, i) = prior_tasks(:,i) .* exp(tmp - max(tmp)); 
	else
		mu(:,i) =  prior_tasks(:,i) .* exp(tmp - max(tmp)) .* (mu(:,i).^damping); 
	end
        mu(:, i) = mu(:, i) / sum(mu(:,i));
    end
    %mu(:, partial_dx) = partial_array;
     
    err = max(abs(old_mu(:)-mu(:)));
    if verbose >= 2, fprintf('%s: %d-th iteration, err=%d\n', funcname, iter, err); end    
    if err < TOL
        break;
    end      
end

if verbose > 0, fprintf('%s: break at %d-th iteration, err=%d\n',funcname, iter, err); end

% decode the labels of tasks
[~, mxdx] = max(mu.*(1+ rand(size(mu))*eps)); % add some random noise to break ties. 
ans_labels = LabelDomain(mxdx);

% estimate the log marginal probability (used for model selection)
%multi_beta2 = @(x)(prod(gamma(x), 2) ./ gamma(sum(x, 2)));
%logbeta2 = @(x)(sum(gammaln(x), 2) - gammaln(sum(x, 2)));
%logZ = sum(sum(mu.*(log(prior_tasks) - log(mu+eps))))  +  ... 
%sum(sum(logbeta2(alpha),3),1) - Nwork*sum(logbeta2(prior_workers),1);
 
%Key = Model;
Key.method = sprintf('%s (Dawid&Skene, two coin model)', funcname);
Key.ans_labels = ans_labels;
%Key.logZ = logZ;
Key.mu = mu;
Key.alpha = alpha;
Key.converge_error = err;
Key.prior_workers = prior_workers;
Key.prior_tasks = prior_tasks;


return;
end





