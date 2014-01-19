function map = querystring_parse( query )
%querystring_parse decodes an urlencodes query string into a structure.
%
% Copyright@ 2013 Wolfgang Kuehn

tokens = regexp(query,'(\w+)=([^&]+)','tokens');
map = struct();
for i=1:length(tokens)
  key = urldecoding(tokens{i}{1});
  value = urldecoding(tokens{i}{2});
  if ~isnan(str2double(value))
    value = str2double(value);
  end
  map.(key) = value;
end

end
