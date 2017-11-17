function [ ret ] = writecsv( filename, Q, K )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
fid = fopen(filename, 'w');
labelLen = size(K, 1);
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
