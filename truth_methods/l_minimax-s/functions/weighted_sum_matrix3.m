function MM = weighted_sum_matrix3(BB, xx)

%size(BB), size(xx)
Ndom = size(BB,1);
MM = sum(BB .* permute(xx(:, ones(Ndom,1), ones(Ndom,1)), [3,2,1]), 3);

return;
end