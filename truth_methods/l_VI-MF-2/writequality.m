function [ ret ] = writequality( filename, W, CM )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
labelCount = size(CM, 1);
fid = fopen(filename, 'w');
for i = 1:length(W)
    fprintf(fid, '%s', W{i});
    for j = 1:labelCount
        for k = 1:labelCount
            fprintf(fid, ',%f', CM(j, k, i));
        end
    end
    fprintf(fid, '\n');
end
ret = 0;
end


