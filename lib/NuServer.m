function server = NuServer(port, routingTable, config)
%server = NuServer(port, routingTable)
%
% Copyright© 2013-2014, Wolfgang Kuehn


  if ~exist('config', 'var')
    config = struct;
  end
  
  if ~isfield(config, 'blocking')
    config.blocking = isdeployed;
  end

  if exist('OCTAVE_VERSION', 'builtin')
    serverObj = javaObject('JavaNuServerOctave', port);
    % Pass arrays as org.octave.Matrix to Java.
    % TODO: Deprecated in Octave 3.8 
    java_convert_matrix(1);
    java_unsigned_conversion(0);
  else
    if config.blocking;
      serverObj = javaObject('JavaNuServer', port);
    else
      serverObj = javaObject('JavaNuServerMatlab', port);
    end
  end
  
  serverObj.logResponseStatus = 1;
  
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
    
    if exist('OCTAVE_VERSION', 'builtin')
      requestBody = serverObj.requestBody;
    else
      requestBody = serverObj.requestBody.';
    end

    response = RestRouterSansException(routingTable, requestMethod, requestUrl, requestBody, headers);
    
    %keyboard;
    
    % TODO: Replace this code by serverObj.setResponseBody(response.body) and handle
    % cases in Java.
    if ~isempty(response.body)
      if exist('OCTAVE_VERSION', 'builtin')
        if ischar(response.body)
          data = int8(0+response.body);
          % TODO: What is the encoding? Ascii?
        else
          data = response.body;
        end
        % Octave byte mapping workaround, see JavaNuServerOctave.java
        if length(data) > 1
          serverObj.setBytes(data, length(data));
        else 
          serverObj.setBytes([data 0], length(data));
        end
      else
        if ischar(response.body)
          serverObj.responseBodyMatlab = unicode2native(response.body, 'UTF-8');
          response.contentType = [response.contentType ';charset=utf-8'];
        else
          serverObj.responseBodyMatlab = response.body;
        end
      end
    end
    
    serverObj.responseStatus = response.status;
    serverObj.responseContentType = response.contentType;
    
  end
  
  function start(serverObj, routingTable)
    if serverObj.isBlocking
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
  NuServerJavaProxy(@(so) RestRouterWrapper(so, routingTable));
  
  server = struct();
  server.start = @() start(serverObj, routingTable);
  if ~serverObj.isBlocking
    % In blocking mode there will be, and should be, no way
    % to stop the server from the MATLAB side.
    server.stop = @stop;
  end

end