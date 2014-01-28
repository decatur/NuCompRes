function server = NuServer(port, routingTable)
%server = NuServer(port, routingTable)
%
% Copyright© 2013-2014, Wolfgang Kuehn


  if exist('OCTAVE_VERSION', 'builtin')
    isBlocking = true;
    serverObj = javaMethod('create', 'JavaNuServer', port, isBlocking);
    % Pass arrays as org.octave.Matrix to Java.
    java_convert_matrix(1);
  else
    isBlocking = isdeployed;
    serverObj = JavaNuServer.create(port, isBlocking);
  end
  
  serverObj.logResponseStatus = 1;
  
  function java_s = javaAssignableString(s)
    if exist('OCTAVE_VERSION', 'builtin')
      java_s = s;
    else
      java_s = java.lang.String(s);
    end
  end

  function RestRouterWrapper(serverObj, routingTable)
    
    % Convert java.lang.String[n][2] to structure with keys normalized like
    % Content-Type to content_type, for example.
    headers = struct();
    javaHeaders = serverObj.requestHeaders;
    headerCount = size(javaHeaders, 1);
    for i=1:headerCount
      header = javaHeaders(i);
      key = char(header(1));
      key = lower(strrep(key, '-', '_'));
      headers.(key) = char(header(2));
    end
       
    requestMethod = char(serverObj.method);
    requestUrl = char(serverObj.uri);
    requestBody = char(serverObj.requestBody);

    response = RestRouterSansException(routingTable, requestMethod, requestUrl, requestBody, headers);
    
    serverObj.responseStatus = javaAssignableString(response.status);
    
    % TODO: Replace this code by serverObj.setResponseBody(response.body) and handle
    % cases in Java.
    if ~isempty(response.body)
      if exist('OCTAVE_VERSION', 'builtin')
        if class(response.body) == 'char'
          serverObj.responseBodyOctave = int8(0+response.body);
        else
          serverObj.responseBodyOctave = response.body;
        end
      else
        if class(response.body) == 'char'
          serverObj.responseBodyMatlab = unicode2native(response.body);
        else
          serverObj.responseBodyMatlab = response.body;
        end
      end
    end
    
    serverObj.responseContentType = javaAssignableString(response.contentType);
  end
  
  function start(serverObj, routingTable, isBlocking)
    if isBlocking
      % MATLAB Standalone application or Octave
      while serverObj.waitForRequest()
        RestRouterWrapper(serverObj, routingTable);
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
  server.start = @() start(serverObj, routingTable, isBlocking);
  if ~isBlocking
    % In blocking mode there will be, and should be, no way
    % to stop the server from the MATLAB side.
    server.stop = @stop;
  end

end