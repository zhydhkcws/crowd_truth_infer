function Key_mvote = marjority_vote_crow_model(Model, varargin)
% solve the crow sourcing model using (weighted) marjority voting 
% Regular marjority voting: Key_mvote = marjority_vote_crow_model(Model)
% Weighted marjority voting; Key_mvote = marjority_vote_crow_model(Model, 'weights', weights_value);
% Weighted marjority voting; weights = fun(worker_p): Key_mvote = marjority_vote_crow_model(Model, 'worker_p', worker_p, 'weights', weights_fun);
% Weighted marjority voting, weights = fun(worker_p), and worker_p is estimated from partially known labels: 
%                           Key_mvote = marjority_vote_crow_model(Model, 'partial_truth', {traindx, trainp}, 'weights', weights_fun);
%
%
% Qiang Liu @ April 2012
%%

[verbose, weights_str, worker_p, partial_truth] = process_varargin(varargin, 'verbose', 0, 'weights', ones(1,Model.Nwork), 'worker_p', [], 'partial_truth', {[], []});

% parameters ...
L = Model.L;
Ntask = Model.Ntask;
Nwork = Model.Nwork;
NeibTask = Model.NeibTask;
breakties = 'random'; % how to break the ties ..

if isa(weights_str, 'numeric')
    weights = weights_str;    
elseif isa(weights_str, 'char')
    
    if isempty(worker_p)
        traindx = partial_truth{1}; trainp = partial_truth{2}(:);
        AA = Model.L(traindx,:); lenA = sum(AA~=0, 1);
        worker_p = (sum(  ((AA -  trainp(:, ones(1, Nwork)))==0) .* (AA~=0),   1) + 1) ./ (lenA  + 2);       
        worker_p(lenA==0) = mean(worker_p(lenA~=0));
    end
    
    switch lower(weights_str)
        case 'uniform'
            weights = ones(1, Model.Nwork);
        case 'linear'
            weights = 2*worker_p-1;
        case {'bayesian', 'log', 'log-odds'}
            weights = log((worker_p+eps)./(1-worker_p+eps));
        case {'bernstein', 'poly'}
            weights = (2*worker_p-1) ./ ( (worker_p+eps).* (1-worker_p+eps)  );
        otherwise
            error('wrong defintion of weights');            
    end
else
    error('wrong defintion of weights');
end    
    



% marjority voting
ans_labels = zeros(1, Ntask);
ans_examplars = cell(1, Ntask);
domb = Model.LabelDomain;
Model.Ndom = length(Model.LabelDomain);

mu = zeros(Model.Ndom, Ntask);
for i = 1:Ntask
    labvec = (L(i,NeibTask{i}));
    wts = weights(NeibTask{i});
    
    if isempty(labvec)
        ans_labels(i) = NaN;
        continue;
    end
       
    %domb = unique(labvec); numb = zeros(size(domb));
    numb = zeros(size(domb));       
    for ii = 1:length(domb)
        %numb(ii) = nnz(labvec==domb(ii));
        numb(ii) = sum(wts(labvec==domb(ii)));
    end
    %numb = numb/sum(numb);
    mu(:, i) = exp(numb - max(numb)); mu(:,i) = mu(:, i)/sum(mu(:,i));
    
    
    dx = find(max(numb) == numb);
    if numel(dx) > 1
        %fprintf('ties:%d', i);
        switch breakties             
            case 'random'
                if verbose >= 1, fprintf('Marjority Voting: ties happens in %d-th task, randomly select one\n', i); end
                dx = dx(randperm(length(dx))); dx = dx(1);
            case 'first'
                if verbose>=1, fprintf('Marjority Voting: ties happens in %d-th task, randomly select one\n', i); end               
                dx = dx(1);
            otherwise
                error('wrong definition of breaking ties');
        end
    end

    %labvec, domb, dx, numb
    lab = domb(dx); %lab
    ans_labels(i) = lab;
    %ans_examplars{i} = NeibTask{i}(labvec == lab);    
end


%Key_mvote = Model;
Key_mvote.method = 'marjority_voting';
Key_mvote.mu = mu;
Key_mvote.ans_labels = ans_labels;
Key_mvote.weights = weights;
Key_mvote.worker_p = worker_p;
%Key_mvote.ans_examplars = ans_examplars;



