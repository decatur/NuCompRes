function [ name, value ] = Header_parse( header )
%Header_parse parses a HTTP header into normalized name and value.
%
% Use HeaderValue_parse() to further parse the structure of the value.
%
% Example
%   [name, value] = Header_parse('Content-Type: multipart/form-data; boundary=----')
%     name  = content_type
%     value = multipart/form-data; boundary=----
%
% See http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
%
% Copyright@ 2013 Wolfgang Kuehn

tokens = regexp(header, '^([^:]+):(.*)$', 'tokens');
if isempty(tokens) || length(tokens{1}) ~= 2
  error('Invalid header: %s', header);
end

% Normalize
name = lower(strrep(strtrim(tokens{1}{1}), '-', '_'));
value = strtrim(tokens{1}{2});

end