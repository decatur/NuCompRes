function response = FileResource( request )
% Serve static text files.

  mimes = struct( ...
    'html', 'text/html', ...
    'js', 'application/javascript', ...
    'css', 'text/css');

  try
    if exist('OCTAVE_VERSION', 'builtin')
      fid = fopen (request.filename, 'r');
      % TODO: Why need to cast?
      response.body = int8(fread(fid, Inf, 'int8'));
      fclose(fid);
    else
      % response.body = fileread( request.filename );
      fid = fopen(request.filename, 'rb');
      response.body = fread(fid, '*uint8')';
      fclose(fid);
    end
 
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



