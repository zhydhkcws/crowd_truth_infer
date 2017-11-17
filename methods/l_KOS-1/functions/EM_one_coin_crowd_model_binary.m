function Key = EM_one_coin_crowd_model_binary(Model, varargin)
%Try to exactly for Dawid Skene and Learning with crowdsource paper (JMLR)'s version without feature
% Works only for binary variables

[verbose, maxIter, TOL, update_prevalence, prior_ell, prior_ell0, issparse] = process_varargin(varargin, ...
    'verbose', 1, 'maxIter', 100, 'TOL', 1e-10, 'update_prevalence', 0, 'ell', [1,1], 'ell0', [1,1], 'issparse', false);

% check: the LabelDomain has to be [1,2] (binary)
if any(Model.LabelDomain ~= [1,2]), error('The Model.LabelDomain has to be [1,2]'); end

if issparse
    L =sparse(Model.L);
else
    L = full(Model.L);
end
Ntask = Model.Ntask;
Nwork = Model.Nwork;
NeibTask = Model.NeibTask;
NeibWork = Model.NeibWork;

%LabelDomain = Model.LabelDomain;
%Ndom= length(LabelDomain);

mu = zeros(1,Ntask);
alphas = zeros(1, Nwork);
%betas = zeros(1, Nwork);

% initialize mu
for i = 1:Ntask
    neib = NeibTask{i}; labs = L(i, neib);
    mu(i) = nnz(labs==1)/length(labs);    
end
preva = .5;

% main iteration 
err = NaN;
for iter=1:maxIter
    % Mstep:
    for j = 1:Nwork
        neib = NeibWork{j}; labs = L(neib, j);
        dx1 = neib(labs==1); dx2 = neib(labs~=1);
        alphas(j) = ( prior_ell(1)-1 + sum(mu(dx1)) + sum(1-mu(dx2)) ) / (prior_ell(1)+prior_ell(2) - 2 + length(neib));        
    end
    if update_prevalence
        preva =  (prior_ell0(1)-1 + sum(mu)) / (prior_ell0(1)+prior_ell0(2)-2 + Ntask);
    end
    
    % Estep:
    old_mu = mu;
    for i = 1:Ntask
        neib = NeibTask{i}; labs = L(i, neib);
        dx1 = neib(labs==1); dx2 = neib(labs~=1);
        ai = prod(alphas(dx1)) * prod(1-alphas(dx2));
        bi = prod(alphas(dx2)) * prod(1-alphas(dx1));
        mu(i) = ai*preva / (ai*preva + bi*(1-preva));    
    end
    
    err = max(abs(old_mu(:)-mu(:)));
    if verbose >=2, fprintf('EM-DawidSkene-one-coin: %d-th iteration, err=%d\n', iter, err); end    
    if err < TOL
        break;
    end    
end

if verbose > 0, fprintf('EM-DawidSkene-one-coin: break at %d-th iteration, err=%d\n', iter, err); end

ans_labels = zeros(1, Ntask);
ans_labels(mu > .5) = 1;
ans_labels(mu < .5) = 2;
dx = find(mu == .5);
if ~isempty(dx)
    ans_labels(dx) = 1 + double(rand(size(dx)) > 0.5);
end


if isfield(Model, 'true_labels') && ~isempty(Model.true_labels)
    Key.prob_err = mean(ans_labels(:) ~= Model.true_labels(:));    
end

%Key = Model;
Key.method = 'EM-DawidSkene-one-coin';
%Key.prior_method = prior_method;
Key.ans_labels = ans_labels;
Key.mu = mu;
Key.alphas = alphas;
%Key.betas = betas;
Key.preva = preva;
Key.converge_error = err;
