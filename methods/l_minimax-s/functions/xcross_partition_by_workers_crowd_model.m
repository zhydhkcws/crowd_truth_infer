function  [xcross_Model, info] = xcross_partition_by_workers_crowd_model(Model, Nfold, varargin)
%[xcross_Model, info] = xcross_partition_crowd_model(Model, Nfold, varargin)
% Partition each worker's labels into $Nfold$ subgroups ($Nfold-1$ for training and 1 for testing)
% varargin: 
%       --- 'truncation' (default = false): If true, remove these workers & items with small degrees    
%       --- 'correct_for_task' (default=false): If true, make sure all the tasks have at least one label for each sub-group
%  
% Qiang Liu, lqiang67@gmail.com 


% truncate works and tasks to make sure work and task degrees are not less than bound_work, bound_task, respectively. 
truncate = process_varargin(varargin, 'truncate', false);
if truncate
    [bound_task, bound_work] = process_varargin(varargin, 'bound_task', Nfold, 'bound_work', Nfold);
    Model =  truncate_model_beyond_threshold(Model, 'bound_task', bound_task, 'bound_work', bound_work);
end

% prepare
L = Model.L; Ntask = Model.Ntask; Nwork = Model.Nwork;
if isfield(Model, 'true_labels') && ~isempty(Model.true_labels), have_true_labels = true; else have_true_labels = false; end
L_opts = {}; if have_true_labels, L_opts = {'true_labels', Model.true_labels, 'LabelDomain', Model.LabelDomain}; end


        %Step 1: first do a random partition on each worker's labels
        Dx = 0*L;        
        for j = 1:Nwork
            neib = Model.NeibWork{j}(:)';
            neib = neib(randperm(length(neib))); % randize 
            neib_Partition = partition_array_tmp(neib, Nfold);
            for kk = 1:Nfold
                Dx(neib_Partition{kk}, j)=kk;
            end    
        end
        
        %Step 2: make sure every task has at least one label (if $correct_for_task$=1)
        correct_task = process_varargin(varargin, 'correct_for_task', false);
        if correct_task
        for i=1:Ntask
            neib = Model.NeibTask{i};
            numb=zeros(1,Nfold);
            for kk=1:Nfold
                numb(kk) = nnz(Dx(i,neib)==kk);            
            end
            zdx = find(numb==0);
            for gg=1:length(zdx)
                [~,mdx]=max(numb); ldx=find(Dx(i,neib)==mdx);
                Dx(i, neib(ldx(1))) = zdx(gg);
                numb(zdx(gg)) = numb(zdx(gg)) + 1;
                numb(mdx) = numb(mdx) -1;
            end            
        end
        end
        
        % Step 3: process the output
        for kk=1:Nfold
            Ltrain = L .* (Dx~= kk);
            Ltest = L .* (Dx==kk);
            xcross_Model.train{kk} = crowd_model(Ltrain, L_opts{:});
            xcross_Model.test{kk} = crowd_model(Ltest, L_opts{:});            
        end



    % for further output
    if nargout > 1
        for kk=1:Nfold
            info.DegWork(:, kk) = full(xcross_Model.test{kk}.DegWork);
            info.DegTask(:, kk) = full(xcross_Model.test{kk}.DegTask);        
            info.L = L;
        end
    end

return;
end



function y = partition_array_tmp(x, Nfold)

nsiz = ceil(length(x)/Nfold);            
dd = zeros(Nfold, nsiz);
dd(1:length(x)) = x;
y = cell(1,Nfold);
for kk =1:Nfold
    y{kk} = dd(kk,dd(kk,:)~=0);
end

return;
end






