clearvars -except filename quali_file
addpath(genpath(pwd));

%% prepare answer Matrix
fid = fopen(filename, 'r', 'n', 'UTF-8'); % question, worker, answer
fgetl(fid); % drop the first line
data = textscan(fid, '%s %s %f', 'Delimiter', ',');
fclose(fid);
if ~exist('uniqueQ', 'var')
    uniqueQ = unique(data{1});
end

fid = fopen(quali_file, 'r', 'n', 'UTF-8'); % worker, question, answer, truth
fgetl(fid); % drop the first line
quali = textscan(fid, '%s %s %f %f', 'Delimiter', ',');
fclose(fid);

uniqueW = unique(data{2});
L = zeros(length(uniqueQ), length(uniqueW));
for i = 1:length(data{1})
    Qindex = find(strcmp(uniqueQ, data{1}(i)));
    Windex = find(strcmp(uniqueW, data{2}(i)));
    L(Qindex, Windex) = data{3}(i) + 1;
end

clearvars -except L uniqueQ quali uniqueW;

L(L>2) = 2;  % only for binay labels

Model = crowd_model(L);
verbose = 0;

Nwork = Model.Nwork;
Ndom = length(Model.LabelDomain);

wpriors = ones(Ndom, Ndom, Nwork);
for i = 1:length(quali{1})
    Windex = find(strcmp(uniqueW, quali{1}(i)));
    tlabel = quali{4}(i) + 1;
    label = quali{3}(i) + 1;
    wpriors(tlabel, label, Windex) = wpriors(tlabel, label, Windex) + 1;
end

Model.wpriors = wpriors;

% mean field on one-coin model (uniform prior)
Key_MFAB11 = variationalEM_two_coin_crowd_model(Model, 'ell', [2,1;1,2], 'maxIter',100, 'TOL', 1e-3, 'verbose', verbose);
writecsv('result.csv', uniqueQ, Key_MFAB11.mu);
exit

