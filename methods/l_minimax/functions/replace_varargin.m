function args = replace_varargin(args, varargin)
% attach_varargin(ARGS, varargin), where ARGS is in the form of {'arg1',value1,'arg2',value2,...},
%    --- if varargin{2*i-1} is in ARGS, change its value to varargin{2*i}
%    --- if varargin{2*i-1} is not in ARGS, add it into ARGS and set its value to varargin{2*i}
%
% Qiang Liu, lqiang67@gmail.com

if ~iscell(varargin)
    error('The second input variable has to be cell');
end
if mod(length(args), 2) || mod(length(varargin),2)
   error('The number of elements in the input has to be even'); 
end

var_names = varargin(1:2:end-1); args_names = args(1:2:end-1);

for i = 1:length(var_names)
   dx = find(strcmpi(var_names{i},args_names));
   if ~isempty(dx)
      args{2*dx} = varargin{2*i};
   else       
       args{end+1} = var_names{i};
       args{end+1} = varargin{2*i};   
   end
end
  

return;
end
