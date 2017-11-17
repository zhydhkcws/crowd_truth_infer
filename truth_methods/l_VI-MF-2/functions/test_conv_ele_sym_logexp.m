x = exp(rand(1,10));

e1 = exp(recursive_ele_sym_logexp(log(x(1:5))));
%e1(1)=0;
e2 = exp(recursive_ele_sym_logexp(log(x(6:end))));
%e2(1)=0;

e = exp(recursive_ele_sym_logexp(log(x)));
%e2 = recursive_ele_sym_logexp(log(x(1:5)));

g = conv(e1, e2);

e1,e2,e,g
g - e
%function elesympoly(x)
%x

%%
x = randn(1,5000);
tic
e = recursive_ele_sym_logexp(x);
toc
tic
E = conv_ele_sym_logexp(x);
toc
norm(e-E)
%%
figure; hold on;
plot(e, '-s');
plot(E, '-r*');

%%
x=randn(1,100);
EE = leave_one_out_ele_sym_logexp(x)
e = ele_sym_logexp(x(2:end))
figure; hold on;
plot(e, '-s');
plot(EE(1,:), '-r*');