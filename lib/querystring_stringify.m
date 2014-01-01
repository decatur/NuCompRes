function [ body ] = querystring_stringify( parts_struct )
%querystring_stringify encodes a struct into an urlencoded string
%
% See http://www.w3.org/TR/html5/forms.html#url-encoded-form-data
% Copyright@ 2013 Wolfgang Kuehn
  
% Submitted to http://rosettacode.org/wiki/URL_decoding#MATLAB_.2F_Octave
function u = urlencoding(s)
  u = '';
  for k = 1:length(s),
      if isalnum(s(k))
        u(end+1) = s(k);
      else
        u=[u,'%',dec2hex(s(k)+0)];
      end;     
  end
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
  body = sprintf('%s%s%s=%s', body, sep, urlencoding(key), urlencoding(value));
  sep = '&';
end

end

