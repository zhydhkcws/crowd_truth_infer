clearvars -except filename
addpath(genpath(pwd));

%% prepare answer Matrix
fid = fopen(filename, 'r', 'n', 'UTF-8'); % question, worker, answer
fgetl(fid); % drop the first line
data = textscan(fid, '%s %s %s', 'Delimiter', ',');
fclose(fid);
if ~exist('uniqueQ', 'var')
    uniqueQ = unique(data{1});
end

uniqueW = unique(data{2});
L = zeros(length(uniqueQ), length(uniqueW));
for i = 1:length(data{1})
    Qindex = find(strcmp(uniqueQ, data{1}(i)));
    Windex = find(strcmp(uniqueW, data{2}(i)));
    L(Qindex, Windex) = str2double(data{3}(i)) + 1;
end

clearvars -except L uniqueQ;

L(L>2) = 2;  % only for binay labels
% true_labels(true_labels~=1) = 2;

Model = crowd_model(L);
verbose = 0;

% this version closely follows the implementation in [KOS]: initializing messages to Norm(1,1), and run only for 10 iterations.
options = {'maxIter',10, 'TOL', 0, 'initialMsg', 'ones+noise', 'verbose', verbose};
Key_kos10 = KOS_method_crowd_model(Model, options{:});
writecsv('result.csv', uniqueQ, Key_kos10.belTask);
exit
