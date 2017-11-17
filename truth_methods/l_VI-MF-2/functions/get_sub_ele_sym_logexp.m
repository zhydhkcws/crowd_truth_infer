function E = get_sub_ele_sym_logexp(a)
% get the elementory polynomial of the first n nodes

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