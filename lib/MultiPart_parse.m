function partsByName = MultiPart_parse( body, boundary )
%MultiPart_parse decodes a multipart/form-data encoded
% string into a structure.
%
% http://www.w3.org/TR/html5/forms.html#multipart-form-data
% http://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
% Copyright@ 2013 Wolfgang Kuehn

typeinfo(body)
assert( strcmpi(typeinfo(body), 'int8 matrix') );

boundary = sprintf('\r\n--%s', boundary);
boundary = int8(0+boundary);
body = [13 10 body];

idx = findPattern2(body, boundary);
% First part is a preamble, last part is closing '--'

partsByName = struct();

for i=1:length(idx)-1
  part = body(idx(i):idx(i+1)-1);

  subIdx = findPattern2(part, [13 10]);
  headers = char(part(subIdx(2)+2:subIdx(4)-2));
  content = part(subIdx(4)+2:end);
  headers = regexp(headers, '\r\n', 'split');

  for j=1:length(headers)
    [headerName, value] = Header_parse(headers{j});
    if strcmp(headerName, 'content_disposition');
      % Assume we are looking at 'form-data; name="foo"'
      elements = HeaderValue_parse( value );
      assert( strcmpi(elements{1}.value, 'form-data') );
      fieldName = elements{1}.params.name;
    end
  end

  
  if ~isnan(str2double(char(content)))
    content = str2double(char(content));
  end
  
  partsByName.(fieldName) = content;
end

end

