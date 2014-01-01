function response = GetVarHandler(path, ~)

  response = evalin('base', path);

end