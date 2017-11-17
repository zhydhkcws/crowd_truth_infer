function Key_mvote = MajorityVote_crowd_model(Model, varargin)
% Result = MajorityVote_crowd_model(Model): Majority voting for crowdsouricing 
% Result = MajorityVote_crowd_model(Model, 'weights', weight_values): Weighted mjority voting where each worker is assigned with an importance weight.  
%
% Output: 
%       -- Result.ans_labels: predicted labels for the items
%       -- Result.error_rate: the prediction error rate (if Model.true_labels exists)
%       -- Result.counts: the voting counts of labels 
%
% Qiang Liu @ April 2012
%%

[verbose, weights, breakties] = ...
    process_varargin(varargin, 'verbose', 1, 'weights', ones(1,Model.Nwork), 'ties', 'random');

% majority voting
L = Model.L; Ntask = Model.Ntask; NeibTask = Model.NeibTask;    
ans_labels = zeros(1, Ntask); domb = Model.LabelDomain; Model.Ndom = length(Model.LabelDomain);
mu = zeros(Model.Ndom, Ntask); mu_count = zeros(Model.Ndom, Ntask);

% main algorithm
for i = 1:Ntask
    labvec = (L(i,NeibTask{i}));
    wts = weights(NeibTask{i});   
    if isempty(labvec), ans_labels(i) = NaN; continue; end
       
    numb = zeros(size(domb));       
    for ii = 1:length(domb), numb(ii) = sum(wts(labvec==domb(ii))); end
    mu_count(:,i) = numb;
    mu(:, i) = exp(numb - max(numb)); mu(:,i) = mu(:, i)/sum(mu(:,i));        
    dx = find(max(numb) == numb);
    
    % break ties
    if numel(dx) > 1
        switch breakties             
            case 'random'
                if verbose >= 2, fprintf('Marjority Voting: ties happens in %d-th task, randomly select one\n', i); end
                dx = dx(randperm(length(dx))); dx = dx(1);
            case 'first'
                if verbose>=2, fprintf('Marjority Voting: ties happens in %d-th task, select the first one\n', i); end               
                dx = dx(1);
            otherwise
                error('wrong definition of breaking ties');
        end
    end
    ans_labels(i) = domb(dx);
end

Key_mvote.method = mfilename;
Key_mvote.ans_labels = ans_labels;
if isfield(Model, 'true_labels') && ~isempty(Model.true_labels)
    %true_labels = Model.true_labels(:)'; dxdx = isfinite(true_labels);
    %Key_mvote.error_rate = mean(ans_labels(dxdx) ~= true_labels(dxdx));    
    [Key_mvote.error_rate, Key_mvote.MoreInfo.error_L1, Key_mvote.MoreInfo.error_L2]=cal_error_using_soft_label(mu, Model.true_labels);
end
Key_mvote.counts = mu_count;


% Print out final information 
if verbose >= 1 
    if isfield(Key_mvote, 'error_rate')
%         printstr = sprintf('%s:', mfilename); 
        % printstr = horzcat(printstr, sprintf('\t-- error rate = %f', Key_mvote.error_rate)); 
        printstr = sprintf('%s:\t-- accu rate = %f', mfilename, 1 - Key_mvote.error_rate); 
        fprintf('%s\n',printstr);
    end
end



return;
end



