function [ body ] = TextPlain_stringify( parts_struct )
%TextPlain_stringify encodes a struct into an HTML form submit string.
%
% http://www.w3.org/TR/html5/forms.html#plain-text-form-data
% Copyright@ 2013 Wolfgang Kuehn

body = '';

fields = fieldnames(parts_struct);

if isempty(fields)
  return;
end

sep = '';
for i=1:length(fields)
  key = fields{i};
  value = num2str(parts_struct.(key));
  body = sprintf('%s%s%s=%s', body, sep, key, value);
  sep = sprintf('\n');
end

end

