function [ name, value, params ] = Header_parse( header )
%Header_parse parses the name and value of an HTTP header.
%
% http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
% Copyright@ 2013 Wolfgang Kuehn

% Example: 
%    name         value                parameter
%   'contentType: multipart/form-data; boundary=--7dd11c272075'

index = strfind(header, ':');
name = header(1:index-1);
[value, params] = HeaderValue_parse(header(index+1:end));

end