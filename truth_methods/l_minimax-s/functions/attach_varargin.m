function args = attach_varargin(args, varargin)
% attach_varargin(ARGS, varargin), where ARGS is in the form of {'arg1',value1,'arg2',value2,...},
%    --- if varargin{2*i-1} is in ARGS, do nothing
%    --- if varargin{2*i-1} is not in ARGS, add into ARGS and set its value to varargin{2*i}
%
% Written by Qiang Liu


if ~iscell(varargin)
    error('the second variable has to be cell');
end
if mod(length(args), 2) || mod(length(varargin),2)
   error('The number of elements in the Input has to be even'); 
end

change_names = varargin(1:2:end-1); args_names = args(1:2:end-1);

for i = 1:length(change_names)
   dx = find(strcmpi(change_names{i},args_names));
   if isempty(dx)
       args{end+1} = change_names{i};
       args{end+1} = varargin{2*i};
   end
end
  

return;
end
