function [body, boundary] = MultiPart_stringify( parts_struct )
%MultiPart_stringify encodes a struct into a multipart/form-data
% encoded string.
%
% http://www.w3.org/TR/html5/forms.html#multipart-form-data
% Copyright@ 2013 Wolfgang Kuehn

body = '';
boundary =  sprintf('%d', round(rand()*1e16));

fields = fieldnames(parts_struct);

for i=1:length(fields)
  value = parts_struct.(fields{i});
  if isnumeric(value)
    value = mat2str(value);
  end
  
  %if isstruct(value)
  %  value = JSON_stringify(value);
  %end
    
  body = sprintf('%s\r\n--%s\r\nContent-Disposition: form-data; name="%s"\r\n\r\n%s', ...
    body, boundary, fields{i}, value);
end

% Closing boundary.
body = sprintf('%s\r\n--%s--', body, boundary);

end

