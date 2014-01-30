function response = FileResource( request )
% Serve static text files.

  mimes = struct( ...
    'html', 'text/html', ...
    'js', 'application/javascript', ...
    'css', 'text/css', ...
    'png', 'image/png');

  
  try
    fid = fopen (request.filename, 'rb');
    if exist('OCTAVE_VERSION', 'builtin')
      % TODO: Why need to cast?
      response.body = int8(fread(fid, Inf, 'int8'));
    else
      response.body = fread(fid, '*uint8')';
    end
    fclose(fid);

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



