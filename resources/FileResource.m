function response = FileResource( request )
% Serve static text files.

  mimes = struct( ...
    'html', 'text/html', ...
    'js', 'application/javascript', ...
    'css', 'text/css');

  try
    response.body = fileread( request.filename );
  catch % err  % the MATLAB way
    err = lasterror(); % Octave bug
    error('http404:Not_Found', '%s', err.message);
  end
  
  [~,~, ext] = fileparts( request.filename );
  ext = ext(2:end);
  if isfield(mimes, ext)
    response.contentType = mimes.(ext);
  else
    response.contentType = 'text/plain';
  end
  
end



