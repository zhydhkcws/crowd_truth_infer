function BB = construct_sufficient_statistics_ordinalminimaxent(Ndom)
% construct the confusion matrix according to the ordinal minimax entropy model
% 
% Qiang Liu @ March 2013



domVec = (1:Ndom)'; domMAT = domVec(:, ones(Ndom,1));
BB = zeros(Ndom,Ndom,4*Ndom); %Bn = Bp;
for s = 1:Ndom
    BB(:,:,s) = (s<= domMAT) .* (s <= domMAT');
    BB(:,:,s+Ndom) = (s<= domMAT) .* (s > domMAT');
    BB(:,:,s+2*Ndom) = (s> domMAT) .* (s > domMAT');
    BB(:,:,s+3*Ndom) = (s> domMAT) .* (s <= domMAT');    
end


%{
domVec = (1:Ndom)'; domMAT = domVec(:, ones(Ndom,1));
BB = zeros(Ndom,Ndom,4*Ndom); %Bn = Bp;
for s = 1:Ndom
    BB(:,:,s) = (s<= domMAT) .* (s <= domMAT');
    BB(:,:,s+Ndom) = -(s<= domMAT) .* (s > domMAT');
    BB(:,:,s+2*Ndom) = (s> domMAT) .* (s > domMAT'); % 
    BB(:,:,s+3*Ndom) = -(s> domMAT) .* (s <= domMAT'); %        
end
%}
