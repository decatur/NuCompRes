function [ value, params ] = HeaderValue_parse( headerValue )
%HeaderValue_parse parses the value of an HTTP header.
%
% http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
% Examples
%   multipart/form-data; boundary=--7dd11c272075
%   Content-Disposition: form-data; name="foo"
%
% Copyright@ 2013 Wolfgang Kuehn
parts = regexp(headerValue, ';', 'split');
value = strtrim(parts{1});

params = struct();
      
for i=2:length(parts)
  [~, tokens] = regexp(parts{i}, '(\w+)=(.*)', 'match', 'tokens');

  key = strtrim(tokens{1}{1});
  paramValue = strtrim(tokens{1}{2});
  % Strip quotes. TODO: Strip only matching quotes!
  paramValue = strrep(paramValue, '"', '');
  if ~isnan(str2double(paramValue))
    paramValue = str2double(paramValue);
  end
  params.(key) = paramValue;
end

end