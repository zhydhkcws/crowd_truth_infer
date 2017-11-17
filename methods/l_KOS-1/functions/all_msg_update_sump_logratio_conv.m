function msg_out = all_msg_update_sump_logratio_conv(msg_in, labs_in, lgh)
% inner message update step for the factor nodes in the sum-product.
%
% Qiang Liu @April 2012
%%

% if broths ==0, take special care
if length(msg_in)==1
    msg_out = lgh(end) - lgh(1);
    return;
end

% otherwise ...
E = leaveoneout_v2_ele_sym_logexp(labs_in .* msg_in);
%E = recursive_ele_sym_xy_logexp(labs_in .* msg_in, zeros(size(msg_in)));
%E = recursive_ele_sym_logexp(labs_in .* msg_in);
%E = conv_ele_sym_logexp(labs_in .* msg_in);

%E = recursive_ele_sym_logexp_mex(labs_in .* msg_in, length(msg_in));
n=size(E,1);
hEplus  = lgh(ones(n,1),   2:end) + E; mxplus = max(hEplus, [], 2);
hEminus = lgh(ones(n,1), 1:end-1) + E; mxminus = max(hEminus, [], 2);
msg_out = log(sum(exp(hEplus - mxplus(:, ones(1,n))), 2)) - log(sum(exp(hEminus - mxminus(:, ones(1,n))), 2)) + mxplus - mxminus;   


return;


%Emx = max(E);
%msg_out = log(sum(h(2:end).*exp(E-Emx))) - log(sum(h(1:end-1).*exp(E-Emx)));


