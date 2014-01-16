function text = readFileToString( file,  encoding ) 
%readFileToString Reads the contents of a file into a String.
%
% Parameters:
%   file - the file to read, must not be null
%   encoding - the encoding to use, must not be null
% 
% Returns:
%   the file contents, never null
%
% Authors:
%   Wolfgang Kuehn 2014-01-14
%   Vlad Atanasiu (atanasiu@alum.mit.edu) 2009-06-13

  assert( ~isempty(encoding), 'The encoding must not be null.' );

  fid = fopen(file, 'r', 'l', encoding);
  text = fscanf(fid, '%c');
  fclose(fid);

end

