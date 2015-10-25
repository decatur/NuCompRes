function json=JSON_stringify(value, space, rootschema)
%json=JSON_stringify(value, space) converts an object to JSON
%   notation representing it.
%
% See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify
% The JSON format and much more can be found at http://json.org.
%
% Arguments
%   value: The value to convert to a JSON string.
%   space: Causes the resulting string to be pretty-printed.
%   rootschema: (Optional) A JSON schema.

%
% Returns
%   json: A string in the JSON format (see http://json.org)
%
% Examples
%   JSON_stringify(struct('foo', 'Hello', 'bar', 1))
%   JSON_stringify(rand(10))
%   JSON_stringify(struct('foo', 'Hello', 'password', 'keep_me_secret')
%   
%   schema = JSON_parse('{"type": "object", "properties": { "bar": { "type": "numeric", "format": "matrix" }}}');
%   JSON_stringify(struct('bar', 1))
%
% Authors:
%   Wolfgang Kuehn 2015-10-26
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
    context.nl = sprintf('\r\n');
  else
    context.indent = '';
    context.nl = '';
  end

  context.gap = '';

  json = str([], value, context, rootschema);

end

function schema = childSchema(schema, key)
  if isfield(schema, 'type') && strcmp(schema.type, 'object') && isfield(schema, 'properties') && isfield(schema.properties, key)
    schema = context.schema.properties.(key);
  end
end

function json = str(key, holder, context, schema)
%  
  % key
  % holder
  
  if isempty(key)
    value = holder;
  elseif iscell(holder)
      s = size(holder);
      if length(s) > 3
        value = holder(key, :);
        value = reshape(value, s(2), s(end));
      elseif s(1) == 2
        value = holder(key, :);
      elseif s(1) == 1
        value = holder{1, key};
      end
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

  if isfield(context, 'schema')
    if strcmp(context.schema.type, 'string')
      json = quote(value, context);
    elseif strcmp(context.schema.type, 'numeric')
      json = specialNumbers2NaN(num2str(complex2nan(value), '%.10g'));
    elseif strcmp(context.schema.type, 'boolean')
      json = mat2str(value);
    elseif strcmp(context.schema.type, 'object')
      json = struct2json(value, context, childSchema(schema, key));
    elseif strcmp(context.schema.type, 'array')
      json = array2json(value, context);
    end
  elseif iscell(value)
    json = cell2json(value, context);
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

end

function txt = struct2json(value, context)
  assert(isstruct(value), 'input is not a struct');
    
  txt = sprintf('{%s', context.nl);
  mind = context.gap;
  context.gap = [context.gap context.indent];
    
  names = fieldnames(value);
  l = length(names);

  for i=1:l
    key = names{i};
    txt = sprintf('%s%s"%s":%s', txt, context.gap, key, str(key, value, context));
    if i<l
      txt = sprintf('%s,%s', txt, context.nl);
    end
  end
    
  if ~isempty(context.indent)
    txt = sprintf('%s\r\n%s}', txt, mind);
  else
    txt = sprintf('%s}', txt);
  end
end

% This is a copy of struct2json with obvious modifications.
function txt = cell2json(value, context)
  assert(iscell(value), 'input is not a struct');
    
  txt = sprintf('[%s', context.nl);
  mind = context.gap;
  context.gap = [context.gap context.indent];
  l = length(value);
  
  for i=1:l
    txt = sprintf('%s%s%s', txt, context.gap, str(i, value, context));
    
    if i<l
      txt = sprintf('%s,%s', txt, context.nl);
    end
  end
    
  if ~isempty(context.indent)
    txt = sprintf('%s\r\n%s]', txt, mind);
  else
    txt = sprintf('%s]', txt);
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

function txt = matrix2D2json(value, context)

  if isnumeric(value) && ~isreal(value)
    value = complex2nan(value);
  end
  
  gap = sprintf('%s%s', context.gap, context.indent);
  
  if ~isempty(context.indent)
    sep = ', ';
    %gap = sprintf('\n%s%s', context.indent, context.gap);
  else
    sep = ',';
    %gap = '';
  end

  fmt = '%.9g';
  colCount = size(value, 2);
  fmt = sprintf(' [\r\n%s%s%s%s\r\n%s],', gap, context.indent, repmat([fmt sep], 1, colCount-1), fmt, gap);
  nd = ndims (value);
  txt = sprintf (fmt, permute (value, [2, 1, 3:nd]));
  txt(1) = '';
  txt(end) = '';
  txt = sprintf('[\r\n%s%s\r\n%s]', gap, txt, context.gap);
end

function txt = array2json(value, context)
  s = size(value);
  mindGap = context.gap;
  
  if length(s) > 2
    context.gap = [context.gap context.indent];
    txt = sprintf('[\r\n%s', context.gap);
    sep = '';
    for i=1:s(1)
      m = value(i, :);
      m = reshape(m, s(2), s(end));
      txt = sprintf('%s%s%s%s', txt, sep, array2json(m, context));
      sep = ',';
    end
    txt = sprintf('%s\r\n%s]', txt, mindGap);
  else
    txt = matrix2D2json(value, context);
  end

end

function txt = quote(value, context)
  assert(ischar(value), 'input is not a string');

  txt = strrep(value, '\', '\\');
  txt = strrep(txt, '"', '\"');
  txt = strrep(txt, sprintf('\n'), '\n');
  txt = strrep(txt, sprintf('\r'), '\r');
  txt = strrep(txt, sprintf('\t'), '\t');
    
  txt = ['"', txt ,'"'];
end
