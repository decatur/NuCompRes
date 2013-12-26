function [ body ] = XWWWForm_stringify( parts_struct )
%XWWWFORM_STRINGIFY encodes a struct into an application/x-www-form-urlencoded
% encoded string.
%
% See http://www.w3.org/TR/html5/forms.html#url-encoded-form-data
% Copyright@ 2013 Wolfgang Kuehn

% urlencode() is missing in the 2012b MCR 
  function urlOut = urlencode(urlIn)
  %URLENCODE Replace special characters with escape characters URLs need
  % Copyright 1984-2008 The MathWorks, Inc.

  urlOut = char(java.net.URLEncoder.encode(urlIn,'UTF-8'));
  end

body = '';

fields = fieldnames(parts_struct);

if isempty(fields)
  return;
end

sep = '';
for i=1:length(fields)
  key = fields{i};
  value = num2str(parts_struct.(key));
  body = sprintf('%s%s%s=%s', body, sep, urlencode(key), urlencode(value));
  sep = '&';
end

end

