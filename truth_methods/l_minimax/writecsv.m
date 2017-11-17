function [ ret ] = writecsv( filename, Q, K, labels)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
fid = fopen(filename, 'w');
labelLen = size(K, 1);
for k = 1:length(labels) - 1
    fprintf(fid, '%d,', labels(k));
end
fprintf(fid, '%d\n', labels(end));
for i = 1:length(Q)
    fprintf(fid, '%s', Q{i});
    for j = 1:labelLen
        fprintf(fid, ',%f', K(j, i));
    end
    fprintf(fid, '\n');
end
fclose(fid);
ret = 0;
end
