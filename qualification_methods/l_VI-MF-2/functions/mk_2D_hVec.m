function [psi1, psi2] = mk_2D_hVec(maxcliquesize, method, varargin)



switch lower(method)
    case {'beta', 'beta-sum'}
        [ell1, ell2] = process_varargin(varargin, 'ell1', [], 'ell2', []);        
        if (length(ell1)~=2) || (length(ell2)~=2)
            error('Please specify ell1, ell2 to be 1X2 vector!!');
        end
        psi1 = zeros(maxcliquesize+1, maxcliquesize+1);
        psi2 = zeros(maxcliquesize+1, maxcliquesize+1);        
        for c1 = 0:(maxcliquesize)
            for c2 = 0:(maxcliquesize)
                psi1(c1+1, c2+1) = beta(c1 + ell1(1), c2 + ell1(2));
                psi2(c1+1, c2+1) = beta(c1 + ell2(1), c2 + ell2(2));
            end
        end                      
        %psi1 = psi1/max(abs(psi1(:)));
        %psi2 = psi2/max(abs(psi2(:)));        
%        dashline;
        return;
        
    case 'beta-sum-mixture'
        [ell1, ell2] = process_varargin(varargin, 'ell1', [], 'ell2', []);        
        if (length(ell1)~=2) || (length(ell2)~=2)
            error('Please specify ell1, ell2 to be 1X2 vector!!');
        end
        psi1 = zeros(maxcliquesize+1, maxcliquesize+1);
        psi2 = zeros(maxcliquesize+1, maxcliquesize+1);        
        for c1 = 0:(maxcliquesize)
            for c2 = 0:(maxcliquesize)
                psi1(c1+1, c2+1) = 0.7*beta(c1 + ell1(1), c2 + ell1(2)) + 0.3*beta(c1 + ell1(2), c2 + ell1(1));
                psi2(c1+1, c2+1) = 0.7*beta(c1 + ell2(1), c2 + ell2(2)) + 0.3*beta(c1 + ell2(2), c2 + ell2(1));
            end
        end                      
        %psi1 = psi1/max(abs(psi1(:)));
        %psi2 = psi2/max(abs(psi2(:)));        
%        dashline;
        return;        
        
        
     case 'beta-max'
        [ell1, ell2] = process_varargin(varargin, 'ell1', [], 'ell2', []);        
        if (length(ell1)~=2) || (length(ell2)~=2)
            error('Please specify ell1, ell2 to be 1X2 vector!!');
        end 
        binent = @(x)(x.*log(x+eps) + (1-x).*log(1-x+eps));        
        psi1 = zeros(maxcliquesize+1, maxcliquesize+1);
        psi2 = zeros(maxcliquesize+1, maxcliquesize+1);        
        for c1 = 0:(maxcliquesize)
            for c2 = 0:(maxcliquesize)                
                r1 = (c1+ell1(1) - 1); n1 = (c1 + c2 + ell1(1) + ell1(2) - 2);
                psi1(c1+1, c2+1) = n1*binent(r1/n1);
                
                r1 = (c1+ell2(1) - 1); n1 = (c1 + c2 + ell2(1) + ell2(2) - 2);
                psi2(c1+1, c2+1) = n1*binent(r1/n1);                
            end
        end          
        psi1 = exp(psi1 - max(psi1(:)));
        psi2 = exp(psi2 - max(psi2(:)));        
        return;

        
     case {'discrete', 'discrete-sum'}
        prior_para = process_varargin(varargin, 'prior_para', []);        
        if isempty(prior_para)  || ~isa(prior_para, 'cell')
            error('Please specify prior_para to be 1X2 cell!!');
        end
        supp1 = prior_para{1}(1,:); prob1 = prior_para{1}(2,:);
        supp2 = prior_para{2}(1,:); prob2 = prior_para{2}(2,:);                
        %binent = @(x)(x.*log(x+eps) + (1-x).*log(1-x+eps));        
        psi1 = zeros(maxcliquesize+1, maxcliquesize+1);
        psi2 = zeros(maxcliquesize+1, maxcliquesize+1);        
        for c1 = 0:(maxcliquesize)
            for c2 = 0:(maxcliquesize) 
                h = 0; %N = c1+c2;
                for kk = 1:length(supp1)
                    h = h + supp1(kk).^(c1) .* (1-supp1(kk)).^(c2) * prob1(kk);
                end
                psi1(c1+1, c2+1) = h;
                
                h = 0; %N = c1+c2;
                for kk = 1:length(supp2)
                    h = h + supp2(kk).^(c1) .* (1-supp2(kk)).^(c2) * prob2(kk);
                end
                psi2(c1+1, c2+1) = h;                                              
            end
        end          
        psi1 = exp(psi1 - max(psi1(:)));
        psi2 = exp(psi2 - max(psi2(:)));        
        return; 
                
     case 'discrete-max'
        prior_para = process_varargin(varargin, 'prior_para', []);        
        if isempty(prior_para) || ~isa(prior_para, 'cell')
            error('Please specify prior_para to be 1X2 cell!!');
        end
        supp1 = prior_para{1}(1,:); prob1 = prior_para{1}(2,:);
        supp2 = prior_para{2}(1,:); prob2 = prior_para{2}(2,:);                
        psi1 = zeros(maxcliquesize+1, maxcliquesize+1);
        psi2 = zeros(maxcliquesize+1, maxcliquesize+1);        
        for c1 = 0:(maxcliquesize)
            for c2 = 0:(maxcliquesize) 
                h = 0; %N = c1+c2;
                for kk = 1:length(supp1)
                    h = max(h, supp1(kk).^(c1) .* (1-supp1(kk)).^(c2) * prob1(kk));
                end
                psi1(c1+1, c2+1) = h;
                
                h = 0; %N = c1+c2;
                for kk = 1:length(supp2)
                    h = max(h, supp2(kk).^(c1) .* (1-supp2(kk)).^(c2) * prob2(kk));
                end
                psi2(c1+1, c2+1) = h;                                              
            end
        end          
        psi1 = exp(psi1 - max(psi1(:)));
        psi2 = exp(psi2 - max(psi2(:)));        
        return;        
                
        
    case 'kos'        
        psi1 = zeros(maxcliquesize+1, maxcliquesize+1);
        psi2 = zeros(maxcliquesize+1, maxcliquesize+1);        
        psi1(1,:) = 1; psi1(:, 1) = 1;
        psi2(1,:) = 1; psi2(:, 1) = 1;                            
        %psi1 = psi1/max(abs(psi1(:)));
        %psi2 = psi2/max(abs(psi2(:)));        
%        dashline;
        return;
                 
    otherwise
        error('mk_2D_hVec: method is wrongly defined.');
end