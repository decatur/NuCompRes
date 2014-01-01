function server = NuServer(port, routingTable)
%server = NuServer(port, routingTable)
% Copyright© 2013, Wolfgang Kuehn

  serverObj = JavaNuServer.create(port, isdeployed);
  serverObj.logLevel = 'DEBUG';

  function RestRouterWrapper(requestMethod_str, requestUrl_str, requestBody_str, contentType)
    
    response = RestRouterSansException(routingTable, requestMethod_str, requestUrl_str, requestBody_str, contentType)
    
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
        RestRouterWrapper(char(serverObj.method), char(serverObj.uri), ...
            char(serverObj.requestBody), char(serverObj.contentType));
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