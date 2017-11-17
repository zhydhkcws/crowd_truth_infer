function negloglike =  Cal_Likelihood_MinimaxEntropy_Ordinal_crowd_model(Model, Key, varargin)
% function negloglike =  Cal_Likelihood_MinimaxEntropy_Ordinal_crowd_model(Model, Key, varargin)
% Calculate the negative loglikelihood for the model returned by MinimaxEntropy_Ordinal_crowd_model.m
%
% Qiang Liu @Jan 2013
%%

[issparse] = process_varargin(varargin, 'issparse', false);
if issparse, L = sparse(Model.L); else L = full(Model.L); end
Ntask = Model.Ntask; NeibTask = Model.NeibTask; %Nwork = Model.Nwork; NeibWork = Model.NeibWork; 
LabelDomain =Model.LabelDomain; Ndom = length(LabelDomain);

xx_work = Key.parameter_worker; xx_task = Key.parameter_task;
if isfield(Key, 'prior_tasks'), prior_tasks = Key.prior_tasks; else prior_tasks = ones(Ndom, Ntask)/Ndom;  end
%if isfield(Key, 'soft_labels'), mu = Key.soft_labels; end
logp_task = zeros(Ndom, Ntask);

BB = construct_sufficient_statistics_ordinalminimaxent(Ndom);
%domVec = (1:Ndom)'; domMAT = domVec(:, ones(Ndom,1));

for i = 1:Ntask
    neib = NeibTask{i}; labs = (L(i, neib));
    logp_task(:,i) = log(prior_tasks(:, i));
    for jdx = 1:length(neib)
        j = neib(jdx);
        tmp = weighted_sum_matrix3(BB, xx_work(:,j)) + weighted_sum_matrix3(BB,xx_task(:, i));        
        logz = logsumexp2_stable(tmp);
        logp_task(:, i) = logp_task(:, i) + tmp(:, labs(jdx)) - logz;
    end 
end
%if isfield(Key, 'mu'), negloglikeBound = - sum(sum(mu .* logp_task))  + sum(sum(log(mu+eps).*mu)); end
negloglike = - sum(log(sum(exp(logp_task),1)/Ndom));
