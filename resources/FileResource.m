function response_str = FileResource( request )
% Serve static, non-binary files.

  try
    response_str = fileread( request.filename );
  catch err
    error('http404:Not_Found', '%s', err.message);
  end
  
end



