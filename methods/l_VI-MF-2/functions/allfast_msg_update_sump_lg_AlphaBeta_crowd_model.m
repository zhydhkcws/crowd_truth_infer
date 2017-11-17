function msg_out = allfast_msg_update_sump_lg_AlphaBeta_crowd_model(msg_in, labs_in, logpsi1, logpsi2)
% inner msg update step for the factor nodes in the sum-product, int the form of log-likelihood ratio 
% When the reliabilities are specified via alpha, beta (sensitivity and specificity)
%
% Qiang Liu @April 2012
%%

% if broths ==0, take special care
if length(msg_in)==1
    if labs_in == 1
        msg_out = logpsi1(2,1) + logpsi2(1,1) -  logpsi1(1,1) - logpsi2(1,2);
    elseif labs_in == -1
        msg_out = logpsi1(1,1) + logpsi2(2,1) -  logpsi1(1,2) - logpsi2(1,1);
    else    
        error('labs_out has to be in the domain of [1,-1], something is wrong');         
    end
    return;
end

% else ...
set1 = find(labs_in==1); nn1 = length(set1);
set2 = find(labs_in==-1); nn2 = length(set2);
[EE1, ee1] = leaveoneout_v2_ele_sym_logexp(labs_in(set1).*msg_in(set1));
[EE2, ee2] = leaveoneout_v2_ele_sym_logexp(labs_in(set2).*msg_in(set2));

%e1 = recursive_ele_sym_logexp(labs_in(set1).*msg_in(set1)); E1 = e1'*ones(1, n2+1);
%e2 = recursive_ele_sym_logexp(labs_in(set2).*msg_in(set2)); E2 = ones(n1+1,1)*e2;

msg_out = zeros(length(labs_in), 1);

% calculate msg_out for set1
if nn1>0
n1 = nn1-1; n2 = nn2;  
E2 = ee2(ones(n1+1,1), :);%ones(n1+1,1)*ee2;    
Bplus = logpsi1( 1 + (0:n1) + 1,    1 + ((n2):-1:0) + 0 ) + logpsi2( 1 + (0:n2) + 0,    1 + ((n1):-1:0) + 0 )'; % % logB(k11, k21) + logB(k22, k12)   
hEplus = Bplus + E2; mxplus = max(hEplus(:));
hheplus =log(sum(exp(hEplus - mxplus), 2)) + mxplus;

Bminus = logpsi1( 1 + (0:n1) + 0,    1 + ((n2):-1:0) + 0 ) + logpsi2( 1 + (0:n2) + 0,    1 + ((n1):-1:0) + 1 )';    
hEminus = Bminus + E2; mxminus = max(hEminus(:));
hheminus =log(sum(exp(hEminus - mxminus), 2)) + mxminus;


tmp1 = hheplus(:, ones(1,n1+1))' + EE1; maxtmp1 = max(tmp1(:)); 
tmp2 = hheminus(:, ones(1,n1+1))' + EE1;  maxtmp2 = max(tmp2(:));
msg_out(set1) = log(sum(exp(tmp1 - maxtmp1),2)) - log(sum(exp(tmp2 - maxtmp2),2)) + maxtmp1 - maxtmp2;
end

% calculate msg_out for set2
if nn2 > 0    
n1 = nn1; n2 = nn2-1;
E1 = ee1(ones(n2+1,1),:)';%ee1'*ones(1, n2+1);
Bplus = logpsi1( 1 + (0:n1) + 0, 1 + ((n2):-1:0) + 0 ) + logpsi2( 1 + (0:n2) + 1, 1 + ((n1):-1:0) + 0 )'; % % logB(k11, k21) + logB(k22, k12)   
hEplus = Bplus + E1; mxplus = max(hEplus(:));
hheplus =log(sum(exp(hEplus - mxplus), 1)) + mxplus;
       
Bminus = logpsi1( 1 + (0:n1) + 0, 1 + ((n2):-1:0) + 1 ) + logpsi2( 1 + (0:n2) + 0, 1 + ((n1):-1:0) + 0 )';    
hEminus = Bminus + E1; mxminus = max(hEminus(:));
hheminus =log(sum(exp(hEminus - mxminus), 1)) + mxminus;

tmp1 = hheplus(ones(n2+1,1),:) + EE2; maxtmp1 = max(tmp1(:));
tmp2 = hheminus(ones(n2+1,1),:) + EE2; maxtmp2 = max(tmp2(:));
msg_out(set2) = log(sum(exp(tmp1 - maxtmp1),2)) - log(sum(exp(tmp2 - maxtmp2),2))  + maxtmp1 - maxtmp2;
end









 
% for jdx = 1:length(set2)
%     j = set2(jdx);   
%     %n1 = nn1; n2 = nn2-1;      
%     %E1 = ee1'*ones(1, n2+1);
%     %e2 = EE2()
%     %E2 = ones(n1+1,1)*EE2(jdx,:);    
%     
%     B1 = logpsi1( 1 + (0:n1) + 0,    1 + ((n2):-1:0) + 0 ); % logB(k11, k21)
%     B2 = logpsi2( 1 + (0:n2) + 1,    1 + ((n1):-1:0) + 0 ); % logB(k22, k12)   
%     hEplus = B1 + B2' + E1 + E2; mxplus = max(hEplus(:));
%         
%     B1 = logpsi1( 1 + (0:n1) + 0,    1 + ((n2):-1:0) + 1 );
%     B2 = logpsi2( 1 + (0:n2) + 0,    1 + ((n1):-1:0) + 0 );    
%     hEminus = B1 + B2' + E1 + E2; mxminus = max(hEminus(:));
%     
%     msg_out(j) = log(sum(exp(hEplus(:) - mxplus))) - log(sum(exp(hEminus(:) - mxminus))) + mxplus - mxminus;    
%     %msg_out(j) = log(sum(sum(exp(hEplus - mxplus)))) - log(sum(sum(exp(hEminus - mxminus)))) + mxplus - mxminus;        
% end
   
%k21 = n2 - k22;
%k12 = n1 - k11;
%lgh1(k11, k21) * lgh2(k22, k12) * E1(k11) * E2(k12)
%lgh1(k11, n1 - k22) * lgh2(k22, n2 - k11)

% otherwise ...
%E = recursive_ele_sym_xy_logexp(labs_in .* msg_in, zeros(size(msg_in)));
%E = recursive_ele_sym_logexp(labs_in .* msg_in);

%hEplus  = lgh(2:end  ) + E; mxplus = max(hEplus);
%hEminus = lgh(1:end-1) + E; mxminus = max(hEminus);
%msg_out = log(sum(exp(hEplus - mxplus))) - log(sum(exp(hEminus - mxminus))) + mxplus - mxminus;   

%Emx = max(E);
%msg_out = log(sum(h(2:end).*exp(E-Emx))) - log(sum(h(1:end-1).*exp(E-Emx)));



