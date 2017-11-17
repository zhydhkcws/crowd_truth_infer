function Key =  variationalEM_two_coin_crowd_model(Model, varargin)
% variational EM (mean field) algorithm on two coin model, see Liu et al. NIPS 2012 (http://www.ics.uci.edu/~qliu1/PDF/crowdsrc_nips12.pdf).
% varargin: 
%     prior_worker (or ell): the alpha parameters of Dirichlet prior of the workers' reliabilities. It has to be a Ndom X Ndom matrix.
%     prior_task: the prior knowledge of tasks' labels. 
%     maxIter: maximum number of iterations.
%     TOL: error tolerance.
%     ...
%
% Qiang Liu @Jan 2013
%%

[verbose, maxIter, TOL, prior_workers,  prior_tasks,  returnMore] = process_varargin(varargin, ...
    'verbose', 1, 'maxIter', 100, 'TOL', 1e-10, {'prior_worker', 'ell'}, [], 'prior_task', [], 'returnMore', 0);


L = Model.L;
Ntask = Model.Ntask;
Nwork = Model.Nwork;
NeibTask = Model.NeibTask;
NeibWork = Model.NeibWork;
LabelDomain =Model.LabelDomain;
Ndom = length(LabelDomain);


%% set default prior parameters
if isempty(prior_tasks)
    prior_tasks = ones(Ndom, Ntask)/Ndom;
end

if isempty(prior_workers)
    prior_workers = ones(Ndom, Ndom);
end



%%
alpha = ones(Ndom, Ndom, Nwork);
mu = zeros(2, Ntask);
% initializing mu
for i = 1:Ntask
    neib = NeibTask{i}; labs = full(L(i, neib));
    for k = 1:length(LabelDomain)
        mu(k, i) = nnz(labs==LabelDomain(k)) / length(labs);    
    end   
end

%%
% main iteration
err = NaN;
for iter = 1:maxIter
    % updating Beta distributions (of the workers) ...
    for j = 1:Nwork
       neib = NeibWork{j}; labs = full(L(neib, j))'; 
       alpha(:, :, j) = prior_workers;
       for ell = 1:Ndom
           dx = neib(labs == LabelDomain(ell));
           alpha(:, ell, j) = alpha(:, ell, j) + sum(mu(:, dx),2);
       end
    end
    
    % updating mu_i(z_i) of the tasks
    old_mu = mu;
    for i = 1:Ntask
        neib = NeibTask{i}; labs = full(L(i, neib));
        tmp = - sum(psi(sum(alpha(:, :, neib), 2)), 3);
        for ell = 1:Ndom
            jdx = neib(labs == LabelDomain(ell));
            tmp = tmp + sum(psi(alpha(:, ell, jdx)), 3);
        end        
        mu(:, i) = prior_tasks(:,i) .* exp(tmp - max(tmp));
        mu(:, i) = mu(:, i) / sum(mu(:,i));

    end
     
    err = max(abs(old_mu(:)-mu(:)));
    if err < TOL
        break;
    end      
end

if verbose > 0, fprintf('variationalEM_crowd_model: break at %d-th iteration, err=%d\n', iter, err); end

% decode the labels of tasks
[~, mxdx] = max(mu.*(1+ rand(size(mu))*eps)); % add some random noise to break ties. 
ans_labels = LabelDomain(mxdx);

% estimate the log marginal probability (used for model selection)
%multi_beta2 = @(x)(prod(gamma(x), 2) ./ gamma(sum(x, 2)));
logbeta2 = @(x)(sum(gammaln(x), 2) - gammaln(sum(x, 2)));

logZ = sum(sum(mu.*(log(prior_tasks) - log(mu+eps))))  +  ... 
sum(sum(logbeta2(alpha),3),1) - Nwork*sum(logbeta2(prior_workers),1);



if isfield(Model, 'true_labels') && ~isempty(Model.true_labels)
    Key.prob_err = mean(ans_labels(:) ~= Model.true_labels(:));    
end

 
%Key = Model;
Key.method = 'variationalEM';
Key.ans_labels = ans_labels;
Key.logZ = logZ;
Key.mu = mu;
Key.alpha = alpha;
Key.converge_error = err;
Key.prior_workers = prior_workers;
Key.prior_tasks = prior_tasks;


return;
end





