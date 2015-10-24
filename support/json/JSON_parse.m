function value = JSON_parse(json, schema)
%data=JSON_parse(string, schema) parses a string as JSON, optionally
% validating against a JSON schema.
%
% https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse
% The JSON format and much more can be found at http://json.org.
%
% Arguments
%   json: The text to parse as JSON.
%   schema: (Optional) A JSON schema struct.
%
% Returns
%  value: The object corresponding to the given JSON text.
%
% Example:
%   JSON_parse('[[[1,2],[3,4]],[[5,6],[7,8]]]')
%   schema = JSON_parse(readFileToString( 'schema.json', 'utf8' ))
%   JSON_parse('{"foo":"Hello", "bar":1}', schema)
%   JSON_parse(['[' repmat('[1, 2, 3],', 1, 100) '[3, false, null],[5,6, 7]]'])
%   JSON_parse('[[1, 2, 3],[3, 4, null],[5,6, 7]]')
%   JSON_parse('[3, 4, null]')
%
% See testJSON_parse.m in the test suite for more examples.
% The specs are at http://www.ietf.org/rfc/rfc4627.txt
%
% authors:
%   Wolfgang Kuehn 2014-01-11 
%   Qianqian Fang 2011/09/09
%   Nedialko Krouchev 2009/11/02
%   François Glineur 2009/03/22
%   Joel Feenstra 2008/07/03
%
% Bugs in predecessor:
% loadjson('[[1,3],[2,4,7,9]]')
% loadjson('[[[1,3],[2,4]],[[1,3],[2,4]]]')
% loadjson(sprintf('{"\n":1}'))
% loadjson(sprintf('{"foo":"\n"}'))
%
% license:
%     BSD, see LICENSE_BSD.txt files for details 
%

  global errors pos inStr len esc index_esc len_esc isoct arraytoken

  pos = 1; len = length(json); inStr = json;
  
  context = struct();
  context.path = '/';

  if nargin >= 2 && strcmp(class(schema), 'struct')
    context.schema = schema;
  end
  
  errors = {};
  isoct = exist('OCTAVE_VERSION', 'builtin');
  arraytoken=find(inStr=='[' | inStr==']' | inStr=='"');
  jstr=regexprep(inStr,'\\\\','  ');
  escquote=regexp(jstr,'\\"');
  arraytoken=sort([arraytoken escquote]);

  % String delimiters and escape chars identified to improve speed:
  esc = find(inStr=='"' | inStr=='\' ); % comparable to: regexp(inStr, '["\\]');
  index_esc = 1; len_esc = length(esc);

  skip_whitespace();
  value = parse_value(context);
  skip_whitespace();
  
  % End of text?
  if pos~=len+1
    error_pos('Unexpected char at position %d');
  end
  
  disp(errors);
end

function child = childContext(context, key)
  child = struct();
  child.path = [context.path key '/'];
  if isfield(context, 'schema') && isfield(context.schema, 'type') && strcmp(context.schema.type, 'object') && isfield(context.schema, 'properties') && isfield(context.schema.properties, key)
    child.schema = context.schema.properties.(key);
  end
end

function validate(value, type, context)
  if ~isfield(context, 'schema')
    return
  end
  
  global errors
  
  if isfield(context.schema, '_ref')
    schema = JSON_parse(readFileToString( context.schema._href, 'utf8' ))
  else
    schema = context.schema
  end
  
  if isfield(schema, 'allOf')
    for i=1:length(schema.allOf)
      validate(value, type, schema.allOf{i})
    end
  elseif ~strcmp(schema.type, type)
    errors = [errors, {sprintf('At %s, expected %s, found %s %s', context.path, schema.type, type, value)}];
  elseif strcmp(schema.type, 'object') && isfield(schema, 'requiredFields')
    for i=1:length(schema.requiredFields)
      if ~isfield(value, schema.requiredFields{i})
        errors = [errors, {sprintf('At %s missing required field %s', context.path, schema.requiredFields{i})}];
      end
    end
  end

end

function mergedObject = mergeDefaults(object, context)
  mergedObject = object;
  
  if ~isfield(context, 'schema') || ~isfield(context.schema, 'properties')
    return
  end

  properties = context.schema.properties;
  propertyNames = fieldnames(properties);

  for i=1:length(propertyNames)
    property = properties.(propertyNames{i});
    if isfield(property, 'default')
      mergedObject.(propertyNames{i}) = property.default;
    end
  end
end

function object = parse_object(context)
  parse_char('{');
  object = struct();
  if next_char ~= '}'
      while 1
          key = parseStr(struct());
          key = valid_field(key);
          parse_char(':');
          object.(key) = parse_value(childContext(context, key));          
          if next_char == '}'
              break;
          end
          parse_char(',');
      end
  end
  parse_char('}');
  validate(object, 'object', context);
  object = mergeDefaults(object, context);
  
end

function object = parse_array(context) % JSON array is written in row-major order
  global pos inStr
  
  lPos = pos;
  
  if regexp(inStr(pos:end), '^(\s*\[\s*){2}[^\[]')
    try
      object = json2D2array();
      return;
    catch
      e = lasterror;
      if strcmp(e.identifier, 'JSONparser:invalidFormat')
        rethrow(e);
      end
      pos = lPos;
    end
  elseif regexp(inStr(pos:end), '^\s*\[\s*[^\[]')  
    try
      object = json1D2array();
      return;
    catch
      e = lasterror;
      if strcmp(e.identifier, 'JSONparser:invalidFormat')
        rethrow(e);
      end
      pos = lPos;
    end
  end 
  
  parse_char('[');
  object = cell(0, 1);

  if next_char ~= ']'
      while 1
        val = parse_value(struct());
        object{end+1} = val;
        if next_char == ']'
            break;
        end
        parse_char(',');
      end
  end
  
  parse_char(']');
end

function vec = json1D2array()
  global pos inStr

  s = inStr(pos:end); % '[1, 2, 3]...'

  p = '\s*(-?\d+(\.\d+)?(e(+|-)?\d+)?|null)\s*';

  pp = [ '^\[(' p ',)*' p '\]' ];
  
  [t, e] = regexp(s, pp, 'tokens', 'end', 'once');

  if isempty(t)
    error('Not a matrix');
  end
  
  s = s(2:e-1);

  s = strrep(s, 'null', 'NaN');

  % nElem = 1+sum(s==',');

  vec = sscanf(s, '%g ,').';
  pos = pos + e;
end

function mat = json2D2array()
  global pos inStr

  s = inStr(pos:end); %'[[1, 2, 3],[3, 4, null],[5,6, 7]]}....'

  m = regexp(s, '^\[\s*\[(\s*\w+\s*,)*\s*\w+\s*\]', 'once', 'match');

  nCols = 1+sum(m==',');

  p = '\s*(-?\d+(\.\d+)?(e(+|-)?\d+)?|null)\s*';

  n = char('0' + (nCols-1));

  pp = [ '\s*\[(' p ',)' '{' n ',' n '}' p '\]\s*' ];
  pp = [ '^\[(' pp ',)*(' pp ')\]' ];

  [t, e] = regexp(s, pp, 'tokens', 'end');

  if isempty(t)
    error('Not a matrix');
  end
  
  s = s(2:e-1);

  s = strrep(s, 'null', 'NaN');

  nRows = sum(s=='[');

  fmt = ['[' repmat('%g ,', 1, nCols-1) '%g],'];

  mat = reshape(sscanf(s, fmt), nCols, nRows)';
  
  pos = pos + e;
end

% function mat = json2array_() % JSON array is written in row-major order
  % level = 1;
  % dims = [1];
  % cDims = [0];
  % mat = [];
  % expectComma = false;
  
  % while 1
    % if next_char == ']'
      % parse_char(']');
      % if length(dims) >= level && (dims(level) && dims(level) ~= cDims(level))
        % error('JSON_parse:internal', 'Not a matrix');
      % end
      % dims(level) = cDims(level);
      % level = level - 1;
      % if level == 1
        % break;
      % end
    % elseif next_char == ','
      % parse_char(',');
      % expectComma = false;
    % else
      % if expectComma
        TODO: Parser should not continue after this.
        % error_pos('Comma expected at position %d');
      % end
      % cDims(level) = cDims(level) + 1;
      % if next_char == '['
        % level = level + 1;
        % cDims(level) = 0;
        % parse_char('[');
      % else
        % try
          % val = parse_number();
        % catch
          % if parse_null()
            % val = NaN;
          % else
            % error('JSON_parse:internal', 'Not a matrix');
          % end
        % end
        % mat(end+1) = val;
        % expectComma = true;
      % end
    % end
  % end
  
  % if length(dims) > 2
    dims(1) is always 1
    % dims = dims(2:end);
  % end
  % mat = reshape(mat, dims);
  
  See TODO in JSON_stringify.array2json()
  % if dims(1) > 1
    % mat = permute(mat, length(size(mat)):-1:1);
  % end
  
% end

function parse_char(c)
  global pos inStr len
  skip_whitespace;
  if pos > len || inStr(pos) ~= c
      error_pos(sprintf('Expected %c at position %%d', c));
  else
      pos = pos + 1;
      skip_whitespace;
  end
end

function c = next_char
  global pos inStr len
  skip_whitespace;
  if pos > len
      c = [];
  else
      c = inStr(pos);
  end
end

function skip_whitespace
  global pos inStr len
  % TODO: rfc4627 only allows space, horizontal tab, line feed and carriage
  % return. isspace() also includes vertical tab, line feed and other
  % Unicode white space. So better use regexp with [\x20\x09\x0A\x0D].
  while pos <= len && isspace(inStr(pos))
      pos = pos + 1;
  end
end

function str = parseStr(context)
  global pos inStr len  esc index_esc len_esc isoct
  assert(inStr(pos) == '"', 'Precondition for parseStr()');
  
  % warning ('off', 'Octave:nested-functions-coerced');
  
  function assertInvalidChars(str)
    startIndices = regexp(str, '[\x0-\x1f]');
    if startIndices
      error_pos('Not a valid string character at %d', -length(str) + startIndices(1) - 1);
    end
  end
  
  pos = pos + 1;
  str = '';
  
  while pos <= len
    while index_esc <= len_esc && esc(index_esc) < pos
        index_esc = index_esc + 1;
    end

    if index_esc > len_esc
      str = [str inStr(pos:len)];
      pos = len + 1;
      break;
    else
      str = [str inStr(pos:esc(index_esc)-1)];
      pos = esc(index_esc);
    end

    nstr = length(str); 
    switch inStr(pos)
      case '"'
        pos = pos + 1;
        % assertInvalidChars(str);
        validate(str, 'string', context);
        return;
      case '\'
        if pos+1 > len
            error_pos('End of text reached right after escape character');
        end
        pos = pos + 1;
        switch inStr(pos)
          case {'"' '\' '/'}
              str(nstr+1) = inStr(pos);
              pos = pos + 1;
          case {'b' 'f' 'n' 'r' 't'}
              str(nstr+1) = sprintf(['\' inStr(pos)]);
              pos = pos + 1;
          case 'u'
              if pos+4 > len
                  error_pos('End of text reached in escaped unicode character');
              end
              
              if isoct
                str(nstr+(1:6)) = inStr(pos-1:pos+4);
              else                        
                str(nstr+1) = native2unicode( [0 0 hex2dec(inStr(pos+1:pos+2)) hex2dec(inStr(pos+3:pos+4))], 'utf-32');
              end
              pos = pos + 5;
        end
      otherwise
        assert(false, 'should never happen');
        pos = pos + 1;
    end
  end
  
  % First check for invalid chars. This will report missing closing quote much more accurately.
  assertInvalidChars(str);

  error_pos('Expected closing quote at end of text');
end

function num = parse_number(context)
  global pos inStr len isoct
  
  horizon = 25;
  
  while true
    numberStr = inStr(pos:min(len, pos+horizon));
    if ~isempty(regexpi(numberStr, '[^0-9\+\-e\.]', 'end')) || pos+horizon >= len
      break;
    end
    % The number MAY reach beyound horizon.
    horizon = 2*horizon;
  end
    
  if isoct~=0
      endIndex = regexpi(numberStr,'^\s*-?(?:0|[1-9]\d*)(?:\.\d+)?(?:e[+\-]?\d+)?','end');
      [num, count] = sscanf(numberStr(1:endIndex), '%f', 1);
      nextIndex = endIndex + 1;
  else
      [num, count, ~, nextIndex] = sscanf(numberStr, '%f', 1);
  end
  
  if count ~= 1
    error_pos('Error reading number at position %d');
  end
  
  pos = pos + nextIndex - 1;
  
  validate(num, 'number', context);
  
end

function isNull = parse_null()
  global pos inStr len
  if pos+3 <= len && strcmp(inStr(pos:pos+3), 'null')
    isNull = true;
    pos = pos + 4;
  else
    isNull = false;
  end
end

function val = parse_value(context)
  global pos inStr len

  switch(inStr(pos))
      case '"'
          val = parseStr(context);
          return;
      case '['
          val = parse_array(context);
          return;
      case '{'
          val = parse_object(context);
          return;
      case {'-','0','1','2','3','4','5','6','7','8','9'}
          val = parse_number(context);
          return;
      case 't'
          if pos+3 <= len && strcmp(inStr(pos:pos+3), 'true')
              val = true;
              pos = pos + 4;
              validate(val, 'boolean', context)
              return;
          end
      case 'f'
          if pos+4 <= len && strcmp(inStr(pos:pos+4), 'false')
              val = false;
              pos = pos + 5;
              validate(val, 'boolean', context);
              return;
          end
      case 'n'
          if parse_null()
            val = [];
            validate(val, 'object', context);
            return;
          end
  end
  error_pos('Value expected at position %d');
end

function error_pos(msg, offset)
  global pos inStr len

  if findstr(msg, '%d')
    % Report position and proximity text.
    index = pos;
    if nargin > 1
      index = pos + offset;
    end
  
    if index > 1
      pre = inStr(max(1, index-15):(index-1));
    else
      pre = '';
    end
    
    if index <= len
      post = inStr(index:min(len, index+20));
    else
      post = '';
    end
    msg = [msg ': %s<error>%s'];
    error('JSONparser:invalidFormat', msg, index, pre, post);
  else
    error('JSONparser:invalidFormat', msg);
  end
end

function validKey = valid_field(key)
% Valid field names must begin with a letter, which may be
% followed by any combination of letters, digits, and underscores.
% Any invalid character will be replaced by 'X'.
  if isempty(key)
    validKey = 'x____';
  else
    validKey = regexprep(key,'^[^A-Za-z]', 'x_');
    validKey = regexprep(validKey,'[^0-9A-Za-z_]', '_');
  end
end

