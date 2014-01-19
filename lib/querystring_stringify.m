function body = querystring_stringify( parts_struct )
%querystring_stringify encodes a struct into an urlencoded string
%
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
  body = sprintf('%s%s%s=%s', body, sep, urlencoding(key), urlencoding(value));
  sep = '&';
end

end

