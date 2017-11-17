function  Key = KOS_method_crowd_model(Model, varargin)
% Implement the method in Karger et.al. 2011.
% varargin: 
%       maxIter: maximum number of iteration
%       TOL: error tolerance       
%       verbose: control output information. 
%
%
% Qiang Liu @ April 2012
%%
if any(Model.LabelDomain~=[1,2]), error('Model.LabelDomain has to be [1,2]'); end

[verbose, TOL, maxIter, prior_a, initialMsg, decode_eps] =  process_varargin(varargin, ...
    'verbose', 1, 'TOL', 1e-10, 'maxIter', 10, 'prior_a', 1/2, 'initialMsg', 'ones+noise', 'decode_eps', 0);

kappa = log(prior_a/(1-prior_a));

%kappa

A = Model.A;
L = Model.L;
L(L==2) = -1;  
NeibTask = Model.NeibTask;
NeibWork = Model.NeibWork;
Ntask = Model.Ntask;
Nwork = Model.Nwork;

dxIJ = find(A); dxJI = find(A');


% intialization 
switch lower(initialMsg)
    case 'ones+noise' % the one used on KOS paper
        msg_J2I = (1 + randn(Nwork, Ntask)).*double(A'); % initial to norm(1,1)
        msg_I2J = zeros(Ntask, Nwork);
    case 'ones'
        msg_J2I = double(A'); % initial to ones
        msg_I2J = zeros(Ntask, Nwork);
        
    % the "minority"-voting, for debugging    
    case 'reverse-ones'        
        msg_J2I = -double(A'); % initial to ones
        msg_I2J = -double(A);
        
    case 'zeros'
        msg_J2I = 0*A';
        msg_I2J = 0*A;        
        
    case 'zeros+noise'
        msg_J2I = 1e-6*(randn(size(A)))*A';
        msg_I2J = 1e-6*(randn(size(A)))*A';
        
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
        for j = neib(:)'
            msg_I2J(i,j) = sum( full(L(i, neib(neib~=j))') .* full(msg_J2I(neib(neib~=j),i)) );%  / length(neib);
        end
    end
    %msg_I2J = msg_I2J/max(abs(msg_I2J(:)));

    % messges from factors to variables
    for j = 1:Nwork
        neib = NeibWork{j};
        for i = neib(:)'
            %msg_J2I(j,i) = sum( full(L(neib(neib~=i),j)) .* full(msg_I2J(neib(neib~=i), j)) )  + kappa;
            msg_J2I(j,i) = sum( full(L(neib(neib~=i),j)) .* full(msg_I2J(neib(neib~=i), j)) ) + kappa;            
        end
    end
    %msg_J2I = msg_J2I/max(abs(msg_J2I(:)));
    
    
    % if NaN
   if any(any(isnan(full(msg_I2J(dxIJ))))) || any(any(isnan(full(msg_J2I(dxJI))))), warning('Message is NaN, break'); err=NaN; break; end    

    % check error ...
    err1 = max(max(   tanh( full(   old_msg_I2J(dxIJ) /2   ) ) - tanh(full(msg_I2J(dxIJ)/2)))); 
    err2 = max(max(tanh(full(old_msg_J2I(dxJI)/2)) - tanh(full(msg_J2I(dxJI)/2))));          
    %err1 = max(abs(old_msg_I2J(:) - msg_I2J(:)));
    %err2 = max(abs(old_msg_J2I(:) - msg_J2I(:)));
    err = full(max(err1, err2));
    %errV(iter)=err;
    if err <= TOL
        break;
    end    
   
end

if verbose > 0, fprintf('KOS_method_crowd_model: stop at iter=%d, err=%d\n', iter, err); end

% decoding
belTask = zeros(1,Ntask);
for i = 1:Ntask
    neib = NeibTask{i};
    belTask(i) = sum( L(i, neib)' .* msg_J2I(neib,i) );   
end

ans_labels = sign(belTask);
ans_labels(ans_labels==-1) = 2;

zdx = find(abs(belTask)<=decode_eps);
if ~isempty(zdx)
    if verbose >= 1, fprintf('KOS_method_crowd_model: ties happens\n'); end
    ans_labels(zdx) = double(rand(size(zdx)) > .5) + 1;
end


%Key = Model;
Key.method = 'KOS';
Key.ans_labels = ans_labels;
Key.belTask = belTask;
Key.msg_I2J = msg_I2J;
Key.msg_J2I = msg_J2I;
Key.converge_error = err;







