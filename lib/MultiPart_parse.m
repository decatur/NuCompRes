function partsByName = MultiPart_parse( body, boundary )
%MultiPart_parse decodes a multipart/form-data encoded
% string into a structure.
%
% http://www.w3.org/TR/html5/forms.html#multipart-form-data
% http://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
% Copyright@ 2013 Wolfgang Kuehn

assert( strcmpi(class(body), 'int8') );

boundary = sprintf('\r\n--%s', boundary);
boundary = int8(0+boundary);
body = [13 10 body];

idx = findPattern2(body, boundary);
% First part is a preamble, last part is closing '--'

partsByName = struct();

for i=1:length(idx)-1
  part = body(idx(i):idx(i+1)-1);

  headerEndIdx = findPattern2(part, [13 10 13 10]);
  headers = part(1:headerEndIdx(1)+1);
  content = part(headerEndIdx(1)+4:end);
  
  crlfIdx = findPattern2(headers, [13 10]);

  for j=2:length(crlfIdx)-1
    header = headers(crlfIdx(j)+2: crlfIdx(j+1)-1);
    [headerName, value] = Header_parse(char(header));
    if strcmp(headerName, 'content_disposition');
      % Assume we are looking at 'form-data; name="foo"'
      elements = HeaderValue_parse( value );
      assert( strcmpi(elements{1}.value, 'form-data') );
      fieldName = elements{1}.params.name;
    end
  end

  
  if strfind(fieldName, '-number')
    fieldName = strrep(fieldName, '-number', '');
    content = str2double(char(content));
  elseif strfind(fieldName, '-string')
    fieldName = strrep(fieldName, '-string', '');
    content = char(content);
  end
  
  partsByName.(fieldName) = content;
end

end

