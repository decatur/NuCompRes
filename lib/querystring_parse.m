function [ map ] = querystring_parse( query )
%querystring_parse decodes an urlencodes query string into a structure.
%
% See http://www.w3.org/TR/html5/forms.html#url-encoded-form-data
% Copyright@ 2013 Wolfgang Kuehn

% urldecoding('http%3A%2F%2Ffoo%20bar%2F') -> http://foo bar/
function u = urldecoding(s)
	u = '';
    k = 1;
	while k<=length(s)
        if s(k) == '%' && k+3 <= length(s)
            u = sprintf('%s%c', u, char(hex2dec(s((k+1):(k+2)))));
            k = k + 3;
        else
            u = sprintf('%s%c', u, s(k));
            k = k + 1;
        end        
	end
end

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
