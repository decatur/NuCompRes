function elements = HeaderValue_parse( headerValue )
%HeaderValue_parse parses the value of an HTTP header into elements.
%
% http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
% For test suite see https://github.com/joyent/http-parser/blob/master/test.c
%
% Example:
%    HeaderValue_parse( 'application/xml;q=0.9,*/*;q=0.8' )
%      [1,1] =
%          value = application/xml
%          params =
%              q = 0.9
%      [1,2] =
%          value = */*
%          params =
%              q = 0.8
%
% Copyright@ 2013 Wolfgang Kuehn

elementsStr = regexp(headerValue, ',', 'split');
elements = cell(1, length(elementsStr));

params = struct();
      
for i=1:length(elementsStr)
  parts = regexp(elementsStr{i}, ';', 'split');
  elements{i} = struct();
  elements{i}.value = strtrim(parts{1});

  params = struct();
  for j=2:length(parts)
    [match, tokens] = regexp(parts{j}, '(\w+)=(.*)', 'match', 'tokens');

    if isempty(match) 
      continue;
    end

    key = strtrim(tokens{1}{1});
    paramValue = strtrim(tokens{1}{2});
    % Strip quotes. TODO: Strip only matching quotes!
    paramValue = strrep(paramValue, '"', '');
    params.(key) = paramValue;
  end
  elements{i}.params = params;
end

end