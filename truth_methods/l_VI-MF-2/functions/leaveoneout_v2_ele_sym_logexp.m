function [EE, e] = leaveoneout_v2_ele_sym_logexp(a)


eps = realmin('double');
len = length(a);

if len == 0, e = 0; EE=0; return; end
if len == 1, e = [0,a]; EE = 0; return; end

E1 = get_sub_ele_sym_logexp(a);
E2 = get_sub_ele_sym_logexp(a(end:-1:1));

EE = zeros(len,len);
EE(1,:) = E2(len-1,1:len);
EE(len,:) = E1(len-1,1:len);
for n=2:len-1
    le = E1(n-1, 1:n); lmx = max(le);
    re = E2(len - n, 1:(len-n+1));  rmx = max(re); 
    %EE(n,:) = log((conv(exp(le), exp(re))));% + lmx + rmx;    
    EE(n,:) = log(max(conv(  exp(le - lmx), exp(re- rmx) ), eps)) + lmx + rmx;
end

if nargout > 1, e = E1(end,:); end
    


return;
end


%%
%{
function E = get_sub_ele_sym_logexp(a)

if isempty(a), E = 0; return; end

E= zeros(length(a), length(a)+1);

E(1,2) = a(1);

for n = 2:length(a)
    %E(n,1) = 0;
    for k = 1:n-1
        ea = E(n-1, k) + a(n); eb = E(n-1, k+1); emx = max(ea, eb);        
        E(n, k+1) = log(exp(ea-emx) + exp(eb-emx)) + emx;
    end
    E(n, n+1) = E(n-1, n) + a(n);
end
%e = E(length(a),:);
return;
end
%}