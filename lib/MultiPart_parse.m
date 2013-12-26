function parts_struct = MultiPart_parse( body, boundary )
%MultiPart_parse decodes a multipart/form-data encoded sting
% string into a structure.
%
% http://www.w3.org/TR/html5/forms.html#multipart-form-data
% http://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
% Copyright@ 2013 Wolfgang Kuehn

boundary = sprintf('\n--%s', boundary);

% Normalize new line \n by stripping carriage return \r
body = strrep(body, sprintf('\r'), '');
body = sprintf('\n%s', body);

parts = regexp(body, regexptranslate('escape', boundary), 'split');
% First part is a preamble, last part is closing '--'
parts_struct = struct();

for i=2:length(parts)-1
  subparts = regexp(parts{i}, '\n\n', 'split');
  headers = regexp(subparts{1}(2:end), '\n', 'split');
  for j=1:length(headers)
    [headerName, value, params] = Header_parse(headers{j});
    if strcmp(headerName, 'Content-Disposition');
      assert( strcmpi(value, 'form-data') );
      fieldName = params.name;
    end
  end
  
  value = subparts{2};
  
  if ~isnan(str2double(value))
    value = str2double(value);
  end
  
  parts_struct.(fieldName) = value;
end

end

