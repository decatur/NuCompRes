function server = NuServer(port, routingTable)
%server = NuServer(port, routingTable)
%
% Copyright© 2013, Wolfgang Kuehn

  serverObj = JavaNuServer.create(port, isdeployed);
  serverObj.logLevel = 'DEBUG';

  function RestRouterWrapper()
    
    % Convert java.lang.String[n][2] to structure with keys normalized like
    % Content-Type to content_type, for example.
    headers = struct();
    for i=1:serverObj.requestHeaders.length()
      header = serverObj.requestHeaders(i);
      key = char(header(1));
      key = lower(strrep(key, '-', '_'));
      headers.(key) = char(header(2));
    end
       
    requestMethod = char(serverObj.method);
    requestUrl = char(serverObj.uri);
    requestBody = char(serverObj.requestBody);

    response = RestRouterSansException(routingTable, requestMethod, requestUrl, requestBody, headers);
    
    serverObj.responseStatus = java.lang.String(response.status);
    if isempty(response.body)
      serverObj.responseBody = [];
    else
      serverObj.responseBody = java.lang.String(response.body);
    end
    
    serverObj.responseContentType = java.lang.String(response.contentType);
  end
  
  function start()
    if isdeployed
      % Standalone application
      while serverObj.waitForRequest()
        
        % Provide the same interface as Matlab.mtFevalConsoleOutput.
        % For this we have to convert java.lang.String[n][2] to cell array
        % of 2-element cell arrays.
        headers = {};
        for i=1:serverObj.requestHeaders.length()
          header = serverObj.requestHeaders(i);
          headers{end+1} = {char(header(1)) char(header(2))};
        end
       
        RestRouterWrapper(char(serverObj.method), char(serverObj.uri), ...
            char(serverObj.requestBody), headers);
      end
    else
      % MATLAB session
      serverObj.waitForRequest();
    end
  end
  
  function stop()
    serverObj.stop();
  end
  
  % Set up global function callable from com.mathworks.jmi.Matlab.mtFeval()
  % Needed for MATLAB Session support
  NuServerJavaProxy(@RestRouterWrapper);
  
  server = struct();
  server.start = @start;
  server.stop = @stop;

end