function hVec = mk_hVec(maxcliquesize, method, varargin)


ell = process_varargin(varargin, 'ell', [1,1]);


hVec = cell(1,maxcliquesize);


switch lower(method)
    case 'beta-max'
        for N = 1:maxcliquesize    
            NHat = N + ell(1) + ell(2) - 2;
            cHat = (0:N) + ell(1) - 1;    
            h = cHat .* log(cHat/NHat+eps) + (NHat-cHat) .* log(1-cHat/NHat + eps); 
            hVec{N} = exp(h - max(h));
        end
                
    case 'beta-max-truncate'
        for N = 1:maxcliquesize    
            NHat = N + ell(1) + ell(2) - 2;
            cHat = (0:N) + ell(1) - 1;    
            h = cHat .* log(cHat/NHat+eps) + (NHat-cHat) .* log(1-cHat/NHat + eps); 
            h = exp(h - max(h)); 
            dx =floor(length(h)/2);  h(1:dx) = h(dx+1);
            hVec{N} = h;
        end


    case {'beta-sum', 'beta'}
        for N = 1:maxcliquesize
            NHat = N + ell(1) + ell(2);
            cHat = (0:N) + ell(1);    
            h = beta(cHat, NHat - cHat);             
            %NHat = N + ell(1) + ell(2) - 2;
            %cHat = (0:N) + ell(1) - 1;    
            %h = beta(cHat+1, NHat - cHat + 1); 
            %hVec{N} = exp(h - max(h));                        
            hVec{N} = h/max(abs(h));
        end
        
        
    case 'linear'
        for N = 1:maxcliquesize
            h = 0:N;
            hVec{N} = exp(h-max(h));
        end
        
    case 'linear-truncate'
        for N = 1:maxcliquesize        
            h = 0:N;  
            dx =floor(length(h)/2);  h(1:dx) = h(dx+1);
            hVec{N} = exp(h-max(h));
        end
        
        
    case 'logistic' % logistic function: logh = log(1+exp(x))
        for N = 1:maxcliquesize
            h = 0:N;  maxh = max(h);
            hVec{N} = exp(-maxh) + exp(h-maxh);
            %h =  1 +  exp(0:N);
        end

    case 'kos' % equivalent to KOS method        
        prior_a = .5;        
        for N = 1:maxcliquesize
            h = zeros(1,N+1); h(1) =1-prior_a; h(end)=prior_a;
            hVec{N} = h/max(abs(h));
        end
        

    case 'shift-kos' % equivalent to KOS method        
        prior_a = ell(1) /(ell(1) + ell(2));        
        for N = 1:maxcliquesize
            h = zeros(1,N+1); h(1) =1-prior_a; h(end)=prior_a;
            hVec{N} = h/max(abs(h));
        end        
        
    case {'spha', 'spha-sum'} % spammer-hammer prior (sum): prob(pj=.5) = prob(pj = 1) = 1/2
        prior_a = ell(1) /(ell(1) + ell(2));
        for N=1:maxcliquesize
            h = (.5)^N*(1-prior_a)*ones(1, N+1);  h(end) = h(end) + prior_a;
            hVec{N}=h/max(abs(h));
        end
        
    case 'spha-max' % spammer-hammer prior (max): prob(pj=.5) = prob(pj = 1) = 1/2
        prior_a = ell(1) /(ell(1) + ell(2));        
        for N=1:maxcliquesize
            h = (.5)^N*(1-prior_a)*ones(1, N+1);  h(end) = max(h(end), prior_a);
            hVec{N}=h/max(abs(h));
        end        
        
    case '151' % prob(pj=0) = prob(pj=.5) = prob(pj = 1) = 1/3
        for N=1:maxcliquesize
            prior_05 = 1/3; prior_1 = 1/3; prior_0 = 1/3;
            h = prior_05*(.5)^N*ones(1, N+1); 
            h(end)=h(end)+prior_1; h(1) = h(1) + prior_0;
            hVec{N} = h/max(abs(h));
        end
           
        
    case {'discrete', 'discrete-sum'} % prob(pj=t_k) = w_k, where 0<= t_k<=1,  0<=w_k<=1 and  sum_k w_k = 1. 
        prior_para = process_varargin(varargin, 'prior_para', [0.5, 1; .5, .5]);
        supp = prior_para(1,:); prob = prior_para(2,:);
        for N=1:maxcliquesize
            h = zeros(1,N+1);
            for j = 1:length(supp)
                h = h + supp(j).^(0:N) .* (1-supp(j)).^(N:-1:0) * prob(j);
            end
            hVec{N} = h/max(abs(h));
        end
        
    case 'discrete-max' % prob(pj=t_k) = w_k, where 0<= t_k<=1,  0<=w_k<=1 and  sum_k w_k = 1. 
        prior_para = process_varargin(varargin, 'prior_para', [0.5, 1; .5, .5]);
        supp = prior_para(1,:); prob = prior_para(2,:);
        for N=1:maxcliquesize
            h = zeros(1,N+1);
            for j = 1:length(supp)
                h = max(h,  supp(j).^(0:N) .* (1-supp(j)).^(N:-1:0) * prob(j));
            end
            hVec{N} = h/max(abs(h));
        end        
        
    otherwise
        error('mk_hVec: method is wrongly defined.');
end