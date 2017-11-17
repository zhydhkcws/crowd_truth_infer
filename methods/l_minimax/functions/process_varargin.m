function [varargout] = process_varargin(options, varargin)
% [varargout] = process_argin(options, varargin)
%
%
% Qiang Liu. Jan, 2011
% Qiang Liu. May, 2012, support multiple name in varargin

names = lower(options(1:2:end-1));


for i = 1:2:length(varargin)
    dx = qiang_strmatch_tmp(varargin{i}, names);
    len = length(dx);
    if len==1
         varargout{(i+1)/2} = options{2*dx};         
    elseif len==0        
         varargout{(i+1)/2} = varargin{i+1};
    elseif len > 1
         varargout{(i+1)/2} = options{2*dx(end)};   
         tmp = '{';
         for k = 1:len, tmp = strcat(tmp, '''', names{dx(k)}, ''', ');end
         tmp = [tmp(1:end-1), '}'];
         warning(sprintf('The names %s corresponds to the same variable. I use the last one! try to merge them! ', tmp));
    end
end


return;
end


function dx = qiang_strmatch_tmp(a, b)
if iscell(a)
    dx = false(size(b));
    for k = 1:length(a)
        dx =dx + strcmpi(a{k}, b);
    end
else
    dx =strcmpi(a, b);
end
   
dx = find(dx);
return;    
end


%{
%The earlier version that does not support multiple names
% Qiang Liu. Jan, 2011
names = lower(options(1:2:end-1));

for i = 1:2:length(varargin)
    dx = strmatch(lower(varargin{i}), names);
    if dx
         varargout{(i+1)/2}= options{2*dx};
    else
         varargout{(i+1)/2}=varargin{i+1};
    end
end
%}
