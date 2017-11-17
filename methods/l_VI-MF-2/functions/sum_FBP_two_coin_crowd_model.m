function  Key_alg = sum_FBP_two_coin_crowd_model(Model, varargin)
% Key_alg = sum_FBP_two_coin_crowd_model(Model, varargin)
% Sum-product belief propagation algorithm for binary two-coin model, see Liu, Peng, Ihler NIPS 2012 (http://www.ics.uci.edu/~qliu1/PDF/crowdsrc_nips12.pdf).
% varargin: 
%       -- TOL: convergence tolerance (default=1e-10)
%       -- maxIter: maximum number of iterations (default = 100)
%       -- initialMsg: initialization of the messages. (default = 'ones')
%       -- prior: the type of prior of workers reliability, e.g., 'beta' (default), 'discrete' ...
%       -- ell1 and ell2:  the parameter of beta prior (if prior = 'beta')
%       -- prior_para: the parameter of discrete prior(if prior = 'discrete', prob(x =prior_para{k}(1,:)) = prior_para{k}(2,:), where k is in [1,2], and sum(prior_para(2,:)) = 1. )
%
%
% Qiang Liu @ April 2012
%%
if any(Model.LabelDomain~=[1,2]), error('Model.LabelDomain has to be [1,2]'); end

[verbose, TOL, maxIter, initialMsg, issparse] =  ...
    process_varargin(varargin, 'verbose', 1, 'TOL', 1e-3, 'maxIter', 100, 'initialMsg', 'ones', 'issparse', false);

maxcliquesize = max(cellfun(@length, Model.NeibWork)); 

% the parameters of prior_method is specified either by prior_ell (if prior_method = 'beta-sum' or 'beta-max') or by prior_para (other cases)
[prior_method, prior_ell1, prior_ell2, prior_para] = process_varargin(varargin, ...
    {'prior_method', 'prior'}, 'beta-sum', 'ell1', [], 'ell2', [], 'prior_para', []);
[psi1, psi2] = mk_2D_hVec(maxcliquesize, prior_method, 'ell1', prior_ell1, 'ell2', prior_ell2, 'prior_para', prior_para);
logpsi1 = log(psi1); logpsi2 = log(psi2);

%figure; plot(lghVec{end}, '-s');
%lghVec{end}

if issparse
    A = sparse(Model.A); L = sparse(Model.L);
else
    A = full(Model.A); L = full(Model.L);    
end
L(L==2) = -1;  
NeibTask = Model.NeibTask;
NeibWork = Model.NeibWork;
Ntask = Model.Ntask;
Nwork = Model.Nwork;

dxIJ = find(A); dxJI = find(A');


% intialization 
switch lower(initialMsg)
    case {'ones+noise', 'norm11'} % the one used on KOS paper
        msg_J2I = (1 + randn(Nwork, Ntask)).*double(A'); % initial to norm(1,1)
        %msg_I2J = zeros(Ntask, Nwork);
        msg_I2J = double(A);
    case 'ones'        
        msg_J2I = double(A'); % initial to ones
        %msg_I2J = zeros(Ntask, Nwork);
        msg_I2J = double(A);

    % the "minority"-voting, for debugging    
    case 'reverse-ones'        
        msg_J2I = -double(A'); % initial to ones
        %msg_I2J = zeros(Ntask, Nwork);
        msg_I2J = -double(A);
        
    case 'zeros'
        msg_J2I = 0*A';
        msg_I2J = 0*A;
        
    % initialize such tha    
    case 'voting'         
        msg_J2I = zeros*double(A');
        for i = 1:Ntask
            neib = NeibTask{i}; lab = full(L(i, neib)); Nj = length(neib);
            lgratio = log( (sum(lab==1)+0.01) ./ (sum(lab==-1)+0.01) );
            msg_J2I(i,neib) = lgratio/Nj;
        end
                   
        
    otherwise
        error('Wrong definition of initialMsg');
end


iter=0;err=NaN;
for iter = 1:maxIter

    % record old msg
    old_msg_I2J = msg_I2J;
    old_msg_J2I = msg_J2I;
    
    % messages from variables to factors
    for i = 1:Ntask
        neib = NeibTask{i};
        labs_in = L(i,neib); msg_in = msg_J2I(neib,i);        
        msg_I2J(i, neib) =  labs_in *msg_in - labs_in' .* msg_in;
        %for j = neib(:)', msg_I2J(i,j) = sum( L(i, neib(neib~=j))' .* (msg_J2I(neib(neib~=j),i)) ); end
    end
    %msg_I2J = msg_I2J/max(abs(msg_I2J(:)));

    % messges from factors to variables
    for j = 1:Nwork
        neib = NeibWork{j};            
        labs_in = L(neib,j);  msg_in =  msg_I2J(neib, j);        
        if ~isempty(neib)
            msg_J2I(j,neib) = allfast_msg_update_sump_lg_AlphaBeta_crowd_model(msg_in, labs_in, logpsi1, logpsi2);                        
            %for i = neib(:)'
            %    labs_out = full(L(i,j));
            %    labs_in = full(L(neib(neib~=i),j));  msg_in =  full(msg_I2J(neib(neib~=i), j));
            %    msg_J2I(j,i) = msg_update_sump_lg_AlphaBeta_crowd_model...
            %        (labs_out, msg_in, labs_in, logpsi1, logpsi2);              
            %end
        end
    end
    %msg_J2I = msg_J2I/max(abs(msg_J2I(:)));
        
    % check NaN
    if any(any(isnan(full(msg_I2J(dxIJ))))) || any(any(isnan(full(msg_J2I(dxJI))))), warning('Message is NaN, break'); err=NaN; break; end    

    % check error ...
    err1 = max(max(tanh(full(old_msg_I2J(dxIJ)/2)) - tanh(full(msg_I2J(dxIJ)/2)))); 
    err2 = max(max(tanh(full(old_msg_J2I(dxJI)/2)) - tanh(full(msg_J2I(dxJI)/2))));       
    %err1 = max(abs(old_msg_I2J(:) - msg_I2J(:)));
    %err2 = max(abs(old_msg_J2I(:) - msg_J2I(:)));
    err = max(err1, err2);
    if verbose >=2, fprintf('sum-FBP-two-coin: iter=%d, convergence error = %d\n', iter, err); end    
    if err <= TOL, break; end
end

if verbose >=1, fprintf('sum-FBP-two-coin: stop at iter=%d, convergence error = %d\n', iter, err); end

% decoding
belTask = zeros(1,Ntask);
for i = 1:Ntask
    neib = NeibTask{i};
    belTask(i) = sum( full(L(i, neib))' .* full(msg_J2I(neib,i)) );   
end

ans_labels = sign(belTask);
ans_labels(ans_labels==-1) = 2;

zdx = find(ans_labels==0);
if ~isempty(zdx)
    if verbose >= 1, fprintf('sum-FBP-two-coin: ties happens\n'); end
    ans_labels(zdx) = double(rand(size(zdx)) > .5) + 1;
end


%Key_alg = Model;
Key_alg.method = 'sum-FBP-two-coin';
Key_alg.prior_method = prior_method;
Key_alg.prior_ell1 = prior_ell1;
Key_alg.prior_ell2 = prior_ell2;
Key_alg.prior_para = prior_para;

Key_alg.ans_labels = ans_labels;
Key_alg.belTask = belTask;
Key_alg.msg_I2J = msg_I2J;
Key_alg.msg_J2I = msg_J2I;
Key_alg.converge_error = err;
Key_alg.belTask = belTask;






