function args = remove_varargin(args, varargin)
% Exactly the same as argfilter.m
%ARGFILTER  Remove unwanted arguments.
% ARGFILTER(ARGS,varargin), where ARGS = {'arg1',value1,'arg2',value2,...},
% and varargin is a character array or cell array of strings. Returns a new
% argument list where the arguments named in varargin is removed


% Written by Tom Minka, Modified by Qiang Liu

i = 1;
while i < length(args)
  if any(strcmpi(args{i},varargin))
    args = args(setdiff(1:length(args),[i i+1]));
  else
    i = i + 2;
  end
end
