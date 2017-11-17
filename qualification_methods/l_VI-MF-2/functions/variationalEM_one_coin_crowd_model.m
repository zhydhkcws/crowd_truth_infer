function Key =  variationalEM_one_coin_crowd_model(Model, varargin)
% variational EM algorithm on one coin model, see Liu et al. NIPS 2012 (http://www.ics.uci.edu/~qliu1/PDF/crowdsrc_nips12.pdf).
%
% varargin: 
%     prior_worker (or ell): the alpha parameters of Dirichlet prior of the workers' reliabilities
%     prior_task: the prior knowledge of tasks' labels. 
%     maxIter: maximum number of iterations
%     TOL: error tolerance.
%     ...
% 
% Qiang Liu @Jan 2013
%%

[verbose, maxIter, TOL, prior_workers, prior_tasks, returnMore] = process_varargin(varargin, ...
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
    prior_workers = ones(Ndom, 1);
end

%%
%alpha = ones(Ndom, Nwork);
alpha_correct = ones(1, Nwork);  alpha_wrong = ones(1, Nwork);
prior_correct = prior_workers(1); prior_wrong = prior_workers(2);


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
       %alpha(:, j) = prior_workers;
       alpha_correct(j) = prior_correct + sum(mu(labs + (neib-1)*Ndom));
       alpha_wrong(j) = prior_wrong + length(neib) - sum(mu(labs + (neib-1)*Ndom)); %sum(sum(mu(:, neib))) - sum(mu(labs + (neib-1)*Ndom));
    end

    tmp = psi(alpha_correct + alpha_wrong);
    psi_correct = psi(alpha_correct) - tmp;
    psi_wrong = psi(alpha_wrong) - tmp;
            
    % updating mu_i(z_i) of the tasks
    old_mu = mu;
    
    for i = 1:Ntask
        neib = NeibTask{i}; labs = full(L(i, neib));        
        tmp2 = zeros(Ndom,1);
        for ell = 1:Ndom
            jdx = neib(labs == LabelDomain(ell)); jdx2 =neib(labs ~= LabelDomain(ell));
            tmp2(ell) = sum(psi_correct(jdx)) + sum(psi_wrong(jdx2));
        end        
        mu(:, i) = prior_tasks(:,i) .* exp(tmp2 - max(tmp2));
        mu(:, i) = mu(:, i) / sum(mu(:,i));
    end
     
    err = max(abs(old_mu(:)-mu(:)));
    if err < TOL
        break;
    end      
end

if verbose > 0, fprintf('variationalEM_one_coin_crowd_model: break at %d-th iteration, err=%d\n', iter, err); end

% decode the labels of tasks
[~, mxdx] = max(mu.*(1+ rand(size(mu))*eps)); % add some random noise to break ties. 
ans_labels = LabelDomain(mxdx);

% estimate the log marginal probability (used for model selection)
%multi_beta2 = @(x)(prod(gamma(x), 2) ./ gamma(sum(x, 2)));
%logbeta2 = @(x)(sum(gammaln(x), 2) - gammaln(sum(x, 2)));
%logbeta1 = @(x)(sum(gammaln(x), 1) - gammaln(sum(x, 1)));


tmp3 = 0;
for j = 1:Nwork
    neib = NeibWork{j}; labs = full(L(neib, j))'; 
    tmp3 = tmp3 + length(neib) - sum(mu(labs + (neib-1)*Ndom));
end

logZ = sum(sum(mu.*(log(prior_tasks) - log(mu+eps))))  +  ... 
sum(betaln(alpha_correct, alpha_wrong)) - Nwork*betaln(prior_correct, prior_wrong)  ...
- tmp3*log(Ndom-1);
%sum(logbeta1(alpha),2) - Nwork*logbeta1(prior_workers);
%sum(sum(logbeta2(alpha),3),1) - Nwork*sum(logbeta2(prior_workers),1);



if isfield(Model, 'true_labels') && ~isempty(Model.true_labels)
    Key.prob_err = mean(ans_labels(:) ~= Model.true_labels(:));    
end

 
%Key = Model;
Key.method = 'variationalEM_one_coin';
Key.ans_labels = ans_labels;
Key.logZ = logZ;
Key.mu = mu;
Key.alpha_correct = alpha_correct;
Key.alpha_wrong = alpha_wrong;
Key.converge_error = err;
Key.prior_workers = prior_workers;
Key.prior_tasks = prior_tasks;
Key.mu = mu;


return;
end





