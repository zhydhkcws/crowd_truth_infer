function logz = logsumexp2_stable(tmp)
            
maxtmp = max(tmp, [], 2);
logz = log(sum(exp(tmp - maxtmp(:, ones(1,size(tmp,2)))), 2)) + maxtmp;  %logz = log(sum(exp(tmp - repmat(maxtmp, Ndom, 1)), 1)) + maxtmp;           

return;
end