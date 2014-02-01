function response = FileResource( request )
% Serve static text files.

  mimes = struct( ...
    'html', 'text/html', ...
    'js', 'application/javascript', ...
    'css', 'text/css', ...
    'png', 'image/png');

  
  try
    fid = fopen (request.filename, 'rb');
    response.body = fread(fid, Inf, '*int8').';
    fclose(fid);
  catch my_caught_error % Octave workaround
    err = my_caught_error;
    error('http404:Not_Found', '%s', err.message);
  end
 
  [~,~, ext] = fileparts( request.filename );
  ext = ext(2:end);
  if isfield(mimes, ext)
    response.contentType = mimes.(ext);
  else
    response.contentType = 'text/plain';
  end
  
  if ~strcmp(response.contentType, 'image/png')
    response.contentType = [response.contentType ';charset=utf-8'];
  end
  
end


