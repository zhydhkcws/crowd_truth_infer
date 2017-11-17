function negloglike =  Cal_Likelihood_MinimaxEntropy_Vector_crowd_model(Model, Key, varargin)
%negloglike =  Cal_Likelihood_MinimaxEntropy_crowd_model(Model, Key, varargin)
%Calculating the neg-loglikelihood for the model returned by MinimaxEntropy_Vector_crowd_model.m
%
% Qiang Liu @Jan 2013
%%

[issparse] = process_varargin(varargin, 'issparse', false);
if issparse, L = sparse(Model.L); else L = full(Model.L); end
Ntask = Model.Ntask; NeibTask = Model.NeibTask; %Nwork = Model.Nwork; NeibWork = Model.NeibWork; 
LabelDomain =Model.LabelDomain; Ndom = length(LabelDomain);

%% set default prior parameters
alpha = Key.parameter_worker;
wX = Key.parameter_task;
if isfield(Key, 'prior_tasks'), prior_tasks = Key.prior_tasks; else prior_tasks = ones(Ndom, Ntask)/Ndom;  end
logp_task = zeros(Ndom, Ntask);

 
for i = 1:Ntask
    neib = NeibTask{i}; labs = (L(i, neib));
    logp_task(:,i) = log(prior_tasks(:, i));
    for jdx = 1:length(neib)
        j = neib(jdx);
        tmp = alpha(:,:, j) + wX(:, i*ones(1,Ndom))';
        logz = logsumexp2_stable(tmp);
        logp_task(:, i) = logp_task(:, i) + tmp(:, labs(jdx)) - logz;
    end 
end
%if isfield(Key, 'mu'), mu = Key.mu; negloglikeBound = - sum(sum(mu .* logp_task))  + sum(sum(log(mu+eps).*mu)); end

negloglike = - sum(log(sum(exp(logp_task)/Ndom,1))); 
  
