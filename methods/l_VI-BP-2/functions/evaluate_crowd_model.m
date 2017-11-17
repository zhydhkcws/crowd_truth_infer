function  [prob_error, Key_alg] = evaluate_crowd_model(Key, Key_algorithms, varargin)
% estimate the acuracy ...
%
% Qiang Liu @April 2012 


[dxTask, use_mu] = process_varargin(varargin, 'dxTask', [], 'use_mu', false);

Nwork = Key.Nwork; Ntask = Key.Ntask; NeibWork = Key.NeibWork; true_labels = Key.true_labels(:);

if ~exist('Key_algorithms', 'var')
    ans_labels_tmp = Key.true_labels;
elseif isa(Key_algorithms, 'struct')    
    ans_labels_tmp = Key_algorithms.ans_labels(:);%getfield(Key_algorithms, 'ans_labels');
else
    ans_labels_tmp = Key_algorithms(:);
end

if isempty(dxTask)
    dxTask = find((~isnan(true_labels)).*(true_labels~=0) );
    dx2 = find((~isnan(ans_labels_tmp)).*(ans_labels_tmp~=0) );    
    if length(dx2)~=length(ans_labels_tmp)
        dxTask= intersect(dxTask, dx2);
        warning('some estimated labels are NaN or zero!!!');
    end
end
    
%process the evidence
%{ 
if ~isfield(Key_algorithms, 'evidence') || isempty(Key_algorithms.evidence) 
    dx = true(1, Ntask);
else
    dx = true(1,Ntask);
    dx(Key_algorithms.evidence(1,:)) = false;    
end
dxTask = find(dx);
%}
%%% start %%%

if ~use_mu
    prob_error = nnz(ans_labels_tmp(dxTask) ~= true_labels(dxTask))/length(dxTask);
else
    d = true_labels(dxTask);
    mu = Key_algorithms.mu(:,dxTask); Ndom = size(mu,1);    
    mu = mu./repmat(max(mu,[],1), Ndom,1); mu = mu.^100;
    mu = mu./repmat(sum(mu,1), Ndom,1);
    tmpmu = zeros(size(mu)); 
    tmpmu(d + (0:length(d)-1)'*Ndom) = 1;               
    prob_error = 1-mean(sum(mu.*tmpmu,1));
end


if nargout >= 2
    %%%%%%%%%% More Outputs %%%%%%%%%%%%
    accuracy_by_Task = sum((Key.L == repmat(ans_labels_tmp(:), 1, Key.Nwork)).*(Key.L~=0), 2) ./ sum(Key.L~=0, 2);
    accuracy_by_Work = sum((Key.L == repmat(ans_labels_tmp(:), 1, Key.Nwork)).*(Key.L~=0), 1) ./ sum(Key.L~=0, 1);
    
    Key_alg = Key_algorithms;
    Key_alg.prob_error = prob_error;
    Key_alg.accuracy_by_Work = accuracy_by_Work;
    Key_alg.accuracy_by_Task = accuracy_by_Task;
    if use_mu, Key_alg.mu_hard = mu; end
end

confusion_matrix = process_varargin(varargin, 'confusion_matrix', false);

if confusion_matrix
    for j = 1:Nwork
       neib = NeibWork{j}; labs = full(L(neib, j))';
        
       ConfMatrix(true_labels(neib) + Ndom*(Key.L(neib)-1), j) = ConfMatrix(true_labels(neib) + Ndom*(Key.L(neib)-1), j) + 1;
    end
    
end
    
    
    