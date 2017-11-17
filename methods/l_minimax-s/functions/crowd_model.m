function Key = crowd_model(L, varargin)
% generate a crowd_model structure based on the labeling matrix L
% The other fields are specified via varargin 
%
%
% Qiang Liu April 2012
%%
if isa(L, 'struct')
    Key = crowd_model(L.L);
    if isfield(L, 'true_labels'), Key.true_labels = L.true_labels; end    
    if isfield(L, 'info'), Key.info = L.info; end        
    return;
end


if isa(L, 'numeric')
    A = (L~=0);    
elseif isa(L, 'cell')
    A = cellfun(@(x)(~isempty(x)), L); 
end

%% parameters ...
Ntask = size(L,1);  % Number of task
Nwork = size(L,2);     % Number of workers

DegTask = sum(A,2)';
DegWork = sum(A,1);
degtask  = max(DegTask);   % number of workers per task
degwork  = max(DegWork);   % number of tasks per worker


% neiborhoods
NeibTask = cell(1, Ntask);
for i = 1:Ntask, NeibTask{i} = find(A(i,:)); end
NeibWork = cell(1, Nwork);
for j = 1:Nwork, NeibWork{j} = find(A(:,j))'; end

Key = initial_fields();


% only for numerical labels
if isa(L, 'numeric')    
    LabelTask = cell(1, Ntask);
    for i = 1:Ntask, LabelTask{i} = L(i,NeibTask{i}); end

    LabelWork = cell(1, Nwork);
    for j = 1:Nwork, LabelWork{j} = (L(NeibWork{j},j))'; end
        
    Key.LabelTask = LabelTask;
    Key.LabelWork = LabelWork;
    
    LabelDomain = unique(L(L~=0));
    Key.LabelDomain = LabelDomain(:)';
    Key.Ndom = length(LabelDomain);                
elseif isa(L, 'cell')
    LabelTask = cell(1, Ntask);
    for i = 1:Ntask, 
        for j = 1:length(NeibTask{i})
            LabelTask{i}(:,j) = L{i, NeibTask{i}(j)}; % the labels of the same task should have the same dimension
        end
    end
    
    LabelWork = cell(1, Nwork);    
    for j = 1:Nwork, 
        for i = 1:length(NeibWork{j})
            LabelWork{j}{i} = L{NeibWork{j}(i), j}; % the labels of different tasks may have different dimensions
        end
    end    
    Key.LabelTask = LabelTask;
    Key.LabelWork = LabelWork;    
    
end

Key.Ntask = Ntask;
Key.Nwork = Nwork;
Key.degtask = degtask;
Key.degwork = degwork;
Key.DegTask = DegTask;
Key.DegWork = DegWork;
Key.NeibTask = NeibTask;
Key.NeibWork = NeibWork;

Key.L = L;
Key.A = A;

for j = 1:2:length(varargin)-1
    %if isfield(Key, varargin{j})
        Key.(varargin{j}) =  varargin{j+1};
    %end
end

Key.Nfeature = size(Key.feature,1);


%Key
%if isfield(Key, 'feature')
%    if size(feature,2) ~= Ntask
%        error('The size of size(feature,2) != Ntask!!!!');
%    end
%end

% output: "Key" includes both data and answers; "Model" only includes the observed data 
%Key.p_correct = Key2.p_correct;
%Key.true_labels = Key2.true_labels;
%Key.prior_type = Key2.prior_type;
%Key.prior_para = Key2.prior_para;

return;
end

function Key = initial_fields()

              Key.L= [];       %: [5000x5000 double]
              Key.A= [];       %: [5000x5000 logical]
        Key.feature= [];       %: [1x5000 double]                            
      Key.LabelTask= [];       %: {1x5000 cell}
      Key.LabelWork= [];       %: {1x5000 cell}
    Key.LabelDomain= [];       %: [1 2]
          Key.Ntask= [];       %: 5000
          Key.Nwork= [];       %: 5000
           Key.Ndom= [];       %: [1 2]              
       Key.Nfeature= 0;       %: 5000          
        Key.degtask= [];       %: 4
        Key.degwork= [];       %: 4
        Key.DegTask= [];       %: [1x5000 double]
        Key.DegWork= [];       %: [1x5000 double]
       Key.NeibTask= [];       %: {1x5000 cell}
       Key.NeibWork= [];       %: {1x5000 cell}
      Key.p_correct= [];       %: [1x5000 double]
    Key.true_labels= [];       %: [1x5000 double]
     Key.info = struct;
     %Key.prior_type= [];       %: 'discrete'
     %Key.prior_para= [];     
        %prior_a: [0.5000 1]
        %prior_b: [0.4000 0.6000]
        return;
end
