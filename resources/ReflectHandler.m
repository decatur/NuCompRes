function response_str = ReflectHandler(path, body)

  if isempty(body)
    body = path;
  end
  
  response_str = sprintf('Length: %d\n%s', length(body), body);

end



