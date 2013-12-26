function response_str = SleepHandler(path, body)

  if isempty(body)
    body = path;
  end
  
  sleepInSeconds = str2double(body);
  
  if isnan(sleepInSeconds)
    response_str = sprintf('Illegal sleep time: %s', body);
  elseif sleepInSeconds <= 5
    pause(sleepInSeconds);
    response_str = sprintf('Slept %d seconds', sleepInSeconds);
  else
    response_str = sprintf('Sleep too long: %d', sleepInSeconds);
  end

end



