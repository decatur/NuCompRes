function [ map ] = XWWWForm_parse( query )
%DECODE_X_WWW_FORM_URLENCODED decodes an application/x-www-form-urlencoded
% string into a structure.
%
% See http://www.w3.org/TR/html5/forms.html#url-encoded-form-data
% Copyright@ 2013 Wolfgang Kuehn

% urldecode() is missing in the 2012b MCR
  function urlOut = urldecode(urlIn)
  %URLDECODE Replace URL-escaped strings with their original characters
  % Copyright 1984-2008 The MathWorks, Inc.

  urlOut = char(java.net.URLDecoder.decode(urlIn,'UTF-8'));
  end

[tokens, ~] = regexp(query,'(\w+)=([^&]+)','tokens','match');
map = struct();
for i=1:length(tokens)
  key = urldecode(tokens{i}{1});
  value = urldecode(tokens{i}{2});
  if ~isnan(str2double(value))
    value = str2double(value);
  end
  map.(key) = value;
end

end