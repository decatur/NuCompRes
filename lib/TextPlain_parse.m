function [ map ] = TextPlain_parse( query )
%TextPlain_parse decodes a text/plain HTML form submit string into a structure.
%
% See http://www.w3.org/TR/html5/forms.html#plain-text-form-data
% Copyright@ 2013 Wolfgang Kuehn

[tokens, ~] = regexp(query,'(\w+)=([^\n]*)','tokens','match');
map = struct();
for i=1:length(tokens)
  key = tokens{i}{1};
  value = tokens{i}{2};
  if ~isnan(str2double(value))
    value = str2double(value);
  end
  map.(key) = value;
end

end