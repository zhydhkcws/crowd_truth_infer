function [error_rate, error_L1, error_L2] = cal_error_using_soft_label(mu, true_labels) 
% to avoid ties, we take uniform probability over all classes that maximumize mu(classes, workers). 
% 1. Average in case of ties
% 2. Ignore when the true_labels are NaN (missing)
%%
dxTask = isfinite(true_labels);mu = mu(:,dxTask); true_labels=true_labels(dxTask); true_labels = true_labels(:)'; 
Ndom = size(mu,1);    
mu = (repmat(max(mu, [], 1), Ndom, 1) == mu);
mu = mu./repmat(sum(mu,1), Ndom,1);
    
tmp1 = repmat((1:Ndom)', 1, size(mu,2));
tmpmu = repmat(true_labels, Ndom, 1);
    
error_rate = mean(sum(  (tmpmu ~= tmp1)    .*mu,1));
error_L1   = mean(sum(  abs(tmpmu - tmp1)  .*mu,1));
error_L2   = sqrt(mean(sum(  (tmpmu - tmp1).^2  .*mu,1)));
