clearvars -except filename known_truth
addpath(genpath(pwd));

%% prepare answer Matrix
fid = fopen(filename, 'r', 'n', 'UTF-8'); % question, worker, answer
fgetl(fid); % drop the first line
data = textscan(fid, '%s %s %f', 'Delimiter', ',');
fclose(fid);
if ~exist('uniqueQ', 'var')
    uniqueQ = unique(data{1});
end

fid = fopen(known_truth, 'r', 'n', 'UTF-8'); % question, truth
fgetl(fid); % drop the first line
known_data = textscan(fid, '%s %f', 'Delimiter', ',');
fclose(fid);

uniqueW = unique(data{2});
L = zeros(length(uniqueQ), length(uniqueW));
known = zeros(length(uniqueQ), 1);
for i = 1:length(data{1})
    Qindex = find(strcmp(uniqueQ, data{1}(i)));
    Windex = find(strcmp(uniqueW, data{2}(i)));
    L(Qindex, Windex) = data{3}(i) + 1; % plus 1 to make all labels positive, 0 indicates no label 
end

for i = 1:length(known_data{1})
    Qindex = find(strcmp(uniqueQ, known_data{1}(i)));
    known(Qindex) = known_data{2}(i) + 1;
end

clearvars -except L uniqueQ uniqueW known;

L(L>2) = 2;  % only for binay labels
known(known>2) = 2;

Model = crowd_model(L, 'known', known);
verbose = 0;
% mean field on one-coin model (uniform prior)
Key_MFAB11 = variationalEM_two_coin_crowd_model(Model, 'ell', [2,1;1,2], 'maxIter',100, 'TOL', 1e-3, 'verbose', verbose);
writecsv('result.csv', uniqueQ, Key_MFAB11.mu);
writequality('quality.csv', uniqueW, Key_MFAB11.alpha);
exit