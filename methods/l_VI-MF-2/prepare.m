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

Model = crowd_model(L);
verbose = 0;
% mean field on one-coin model (uniform prior)
Key_MFAB11 = variationalEM_two_coin_crowd_model(Model, 'ell', [2,1;1,2], 'maxIter',100, 'TOL', 1e-3, 'verbose', verbose);
writecsv('result.csv', uniqueQ, Key_MFAB11.mu)
exit

