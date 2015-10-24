function writeStringToFile( file, data, encoding )
%writeStringToFile Writes a String to a file creating the file if it does
% not exist.
  
  assert( ~isempty(encoding), 'The encoding must not be null.' );

  fid = fopen(file, 'w', 'l', encoding);
  fprintf(fid, '%c', data);
  fclose(fid);

end

