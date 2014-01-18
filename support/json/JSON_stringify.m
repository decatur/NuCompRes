function json=JSON_stringify(value, replacer, space)
%json=JSON_stringify(value, replacer, space) converts an object to JSON
%   notation representing it.
%
% See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify
% The JSON format and much more can be found at http://json.org.
%
% Arguments
%   value: The value to convert to a JSON string.
%   replacer: If a function, transforms values and properties encountered while
%       stringifying; if an array, specifies the set of properties included in
%       objects in the final string.
%   space: Causes the resulting string to be pretty-printed.
%
% Returns
%   json: A string in the JSON format (see http://json.org)
%
% Examples
%   JSON_stringify(struct('foo', 'Hello', 'bar', 1))
%   JSON_stringify(rand(10))
%   JSON_stringify(struct('foo', 'Hello', 'password', 'keep_me_secret'), ...
%                   @(obj, key, value) {value '#####'}{1+strcmp(key,'password')})
%
% Authors:
%   Wolfgang Kuehn 2014-01-9
%   Qianqian Fang 2011-09-09


  context = struct('isOctave', exist('OCTAVE_VERSION', 'builtin'));
  if exist('replacer', 'var') && ~isempty(replacer)
    context.replacer = replacer;
  end

  if exist('space', 'var')
    if isnumeric(space)
        context.indent = repmat(' ', 1, space);
    else
        context.indent = space;
    end
    context.nl = sprintf('\n');
  else
    context.indent = '';
    context.nl = '';
  end

  context.gap = '';

  json = str([], value, context);

end

function json = str(key, holder, context)
% 
    
  if isempty(key)
    value = holder;
  elseif iscell(holder)
    value = holder{key};
  elseif isstruct(holder)
    if isnumeric(key)
      % holder is struct array.
      value = holder(key);
    else
      % holder is struct.
      value = holder.(key);
    end
  else
      assert(false);
  end

  if iscell(value)
    json = array2json(value, context);
  elseif ismatrix(value)
    if isempty(value)
      json = 'null';
    elseif size(value, 1)==1 && ischar(value)
      json = quote(value, context);
    elseif isequal(size(value), [1 1])
      if isnumeric(value)
        json = specialNumbers2NaN(num2str(complex2nan(value), '%.10g'));
      elseif islogical(value)
        json = mat2str(value);
      elseif isstruct(value)
        json = struct2json(value, context);
      else
        assert(false);
      end
    else
      json = array2json(value, context);
    end
  elseif isstruct(value)
    % Scalar struct; Octave only
    json = struct2json(value, context);
  else
    assert(false);
  end
  
  if isfield(context, 'replacer')
    % TODO: Top level?
    replacer = context.replacer;
    json = replacer(holder, key, json);
  end

end

function txt=struct2json(value, context)
  assert(isstruct(value), 'input is not a struct');
    
  txt = sprintf('{%s', context.nl);
  mind = context.gap;
  context.gap = [context.gap context.indent];
    
  names = fieldnames(value);

  for i=1:length(names)
    key = names{i};
    txt = sprintf('%s%s"%s":%s', txt, context.gap, key, str(key, value, context));
    if i<length(names)
      txt = sprintf('%s,%s', txt, context.nl);
    end
  end
    
  if ~isempty(context.indent)
    txt = sprintf('%s\n%s}', txt, mind);
  else
    txt = sprintf('%s}', txt);
  end
end

% Replace complex numbers by NaNs.
function newNumber = complex2nan(number)
  newNumber = number;
  newNumber(number~=conj(number)) = NaN;
end

function newText = specialNumbers2NaN(text)
  % JSON has no notion of those special IEEE 754 numbers.
  % Note: we have to replace -Inf before Inf!
  newText = strrep(text, '-Inf','null');
  newText = strrep(newText, 'Inf','null');
  newText = strrep(newText, 'NaN','null');
end

function txt=array2json(value, context)
  mindGap = context.gap;
  
  s = size(value);
  
  % MATLAB uses column-major order, see
  % http://en.wikipedia.org/wiki/Row-major_order.
  % Transform to row-major order.
  % TODO: Try to avoid this copy!
  value = permute(value, length(s):-1:1);
  
  isNumericArray = isnumeric(value);
  
  if isNumericArray && ~isreal(value)
    value = complex2nan(value);
  end
  
  if s(1) == 1
      s = s(2:end);
  end

  p = zeros(1,length(s));
  for k=1:length(s)
    p(k) = prod(s(k:length(s)));
  end
  
  %p
  gap = '';
  
  if ~isempty(context.indent)
    sep = sprintf(',\n');
  else
    sep = ',';
  end

  txt = '';
  level = -1;
  
  for i=1:s(end):numel(value)
      
    mo = mod(i-1, p);
    if ( find(~mo) == level)
      txt = sprintf('%s%s', txt, sep);
    end
      
    %mo
    
    for k=1:length(mo)
      if mo(k) == 0
        gap = [mindGap repmat(context.indent, 1, k-1)];
        if k == 1 && all(mo == 0)
          txt = sprintf('%s[%s', txt, context.nl);
        else
          txt = sprintf('%s%s[%s', txt, gap, context.nl);
        end
      end
    end
    
    gap = [gap context.indent];
    context.gap = gap;
    
    if isNumericArray
      % This will handle both numerical and logical arrays.
      array = mat2str(value(i:(i+s(end)-1)), 10);
      % Depending on dimensionality we have to either replace ';' or ' '.
      array = strrep(array, '[', ''); array = strrep(array, ']', '');
      array = strrep(array, ' ', [',' context.nl gap]);
      array = strrep(array, ';', [',' context.nl gap]);
      
      txt = sprintf('%s%s%s', txt, gap, specialNumbers2NaN(array));
    else
      c = value(i:(i+s(end)-1));
      for j=1:length(c)
        txt = sprintf('%s%s%s', txt, gap, str(j, c, context));
        if j < length(c)
          txt = sprintf('%s%s', txt, sep);
        end
      end
      txt = sprintf('%s', txt);
    end
      
    mo = mod(i-1+s(end), p);
    level = find(~mo);
    for k=length(mo):-1:1
      if mo(k) == 0
        gap = [mindGap repmat(context.indent, 1, k-1)];
        context.gap = gap;
        txt = sprintf('%s%s%s]', txt, context.nl, gap);
      end
    end

  end

end

function txt=quote(value, context)
  assert(ischar(value), 'input is not a string');

  txt=strrep(value, '\', '\\');
  txt=strrep(txt, '"', '\"');
  txt=strrep(txt, sprintf('\n'), '\n');
  txt=strrep(txt, sprintf('\r'), '\r');
  txt=strrep(txt, sprintf('\t'), '\t');
    
  txt = ['"', txt ,'"'];
end
