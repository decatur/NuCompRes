function value = JSON_parse(json, reviver)
%data=JSON_parse(string, reviver) parses a string as JSON, optionally
% transforming the value produced by parsing.
%
% https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse
% The JSON format and much more can be found at http://json.org.
%
% Arguments
%   json: The text to parse as JSON.
%   reviver: If a function, prescribes how the value originally produced
%       by parsing is transformed, before being returned.
%
% Returns
%  value: The object corresponding to the given JSON text.
%
% Example:
%   JSON_parse('[[[1,2],[3,4]],[[5,6],[7,8]]]')
%   JSON_parse('{"foo":"Hello", "bar":1}', @(obj, key, value) class(value))
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

  global pos inStr len esc index_esc len_esc isoct arraytoken rev

  pos = 1; len = length(json); inStr = json;
  if nargin >= 2 && strcmp(class(reviver), 'function_handle')
    rev = reviver;
  else
    rev = [];
  end
  
  isoct=exist('OCTAVE_VERSION');
  arraytoken=find(inStr=='[' | inStr==']' | inStr=='"');
  jstr=regexprep(inStr,'\\\\','  ');
  escquote=regexp(jstr,'\\"');
  arraytoken=sort([arraytoken escquote]);

  % String delimiters and escape chars identified to improve speed:
  esc = find(inStr=='"' | inStr=='\' ); % comparable to: regexp(inStr, '["\\]');
  index_esc = 1; len_esc = length(esc);

  skip_whitespace();
  value = parse_value();
  skip_whitespace();
  
  % We should have reached the end of the text.
  if pos~=len+1
    error_pos('Unexpected char at position %d');
  end
end

function object = parse_object()
  global rev
  parse_char('{');
  object = struct();
  if next_char ~= '}'
      while 1
          key = parseStr();
          key = valid_field(key);
          parse_char(':');
          object.(key) = parse_value();
          
          if ~isempty(rev)
            object.(key) = rev(object, key, object.(key));
          end
          
          if next_char == '}'
              break;
          end
          parse_char(',');
      end
  end
  parse_char('}');
end

function object = parse_array() % JSON array is written in row-major order
  global pos
  lPos = pos;
  
  %object = parse_as_mat();
  %return;
  
  try
    object = json2array();
    return;
  catch
    e = lasterror;
    if strcmp(e.identifier, 'JSONparser:invalidFormat')
      rethrow(e);
    end
    pos = lPos;
  end
  
  parse_char('[');
  object = cell(0, 1);

  if next_char ~= ']'
      while 1
        val = parse_value();
        object{end+1} = val;
        if next_char == ']'
            break;
        end
        parse_char(',');
      end
  end
  
  parse_char(']');
end

function mat = json2array() % JSON array is written in row-major order
  level = 1;
  dims = [1];
  cDims = [0];
  mat = [];
  expectComma = false;
  
  while 1
    if next_char == ']'
      parse_char(']');
      if length(dims) >= level && (dims(level) && dims(level) ~= cDims(level))
        error('JSON_parse:internal', 'Not a matrix');
      end
      dims(level) = cDims(level);
      level = level - 1;
      if level == 1
        break;
      end
    elseif next_char == ','
      parse_char(',');
      expectComma = false;
    else
      if expectComma
        % TODO: Parser should not continue after this.
        error_pos('Comma expected at position %d');
      end
      cDims(level) = cDims(level) + 1;
      if next_char == '['
        level = level + 1;
        cDims(level) = 0;
        parse_char('[');
      else
        try
          val = parse_number();
        catch
          if parse_null()
            val = NaN;
          else
            error('JSON_parse:internal', 'Not a matrix');
          end
        end
        mat(end+1) = val;
        expectComma = true;
      end
    end
  end
  
  if length(dims) > 2
    % dims(1) is always 1
    dims = dims(2:end);
  end
  mat = reshape(mat, dims);
  
  % See TODO in JSON_stringify.array2json()
  if dims(1) > 1
    mat = permute(mat, length(size(mat)):-1:1);
  end
  
end

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

function str = parseStr()
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

function num = parse_number()
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

function val = parse_value()
  global pos inStr len

  switch(inStr(pos))
      case '"'
          val = parseStr();
          return;
      case '['
          val = parse_array();
          return;
      case '{'
          val = parse_object();
          return;
      case {'-','0','1','2','3','4','5','6','7','8','9'}
          val = parse_number();
          return;
      case 't'
          if pos+3 <= len && strcmp(inStr(pos:pos+3), 'true')
              val = true;
              pos = pos + 4;
              return;
          end
      case 'f'
          if pos+4 <= len && strcmp(inStr(pos:pos+4), 'false')
              val = false;
              pos = pos + 5;
              return;
          end
      case 'n'
          if parse_null()
            val = [];  
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
