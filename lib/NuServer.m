function server = NuServer(port, routingTable)
%server = NuServer(port, routingTable)
% Copyright© 2013, Wolfgang Kuehn

  serverObj = JavaNuServer.create(port, isdeployed);
  serverObj.logLevel = 'DEBUG';
  
  function c = mixInStruct( a, b )
    c = a;
    for field = fieldnames( b)'
      c.( field{ 1}) = b.( field{ 1});
    end
  end
  
  function [status, response, responseContentType] = RestRouter(requestMethod, requestUrl, requestBody, contentTypeHeader)

    fprintf('%s %s %s\n%s\n', requestMethod, requestUrl, contentTypeHeader, requestBody);

    if ~isempty(contentTypeHeader)
      [contentType, contentTypeParams] = HeaderValue_parse(contentTypeHeader);
    else
      contentType = 'text/plain';
    end
    
    % Example requestUrl: '/foo/:id?arg=3
    [~, tok] = regexp(requestUrl, '^([^?]*)(\?.*)?$', 'match', 'tokens');
    
    % /foo/:id
    path = tok{1}{1};
    % ?arg=3
    query = tok{1}{2};

    if ~isempty(query)
      query_struct = XWWWForm_parse(query(2:end));
    else
      query_struct = struct();
    end
    
    % Example: 'POST /foo/:id'
    requestAction = [requestMethod ' ' path];
    
    for i = 1:length(routingTable)
      route = routingTable{i};
      
      routeAction = route{1};
      
      % Allow for id names only valid MATLAB identifiers.
      % Allow for id values the @ and all unreserved chars of RFC3986:
      %     ALPHA / DIGIT / "-" / "." / "_" / "~"
      % We use MATLABs named token regular expressions, for which the
      % example becomes 'POST /foo/(?<id>[a-zA-Z0-9-_~.%@]+)'
      routeAction = regexprep(routeAction, ':([a-zA-Z0-9]\w*)', '(?<$1>[a-zA-Z0-9-_~.%@]+)');
      
      routeAction = ['^' routeAction '$'];
 
      tokenNames = regexp(requestAction, routeAction, 'names');

      if ~isempty(tokenNames)
        fHandle = route{2};
        
        
        if strcmp(contentType, 'application/x-www-form-urlencoded')
          request_struct = XWWWForm_parse(requestBody);
        elseif strcmp(contentType, 'multipart/form-data')
          request_struct = MultiPart_parse(requestBody, contentTypeParams.boundary);
        elseif strcmp(contentType, 'text/plain')
          % request_struct = TextPlain_parse(requestBody);
          request_struct = struct();
          request_struct.body = requestBody;
        else
          error('http400:Bad_Request', 'Invalid Content-Type: %s', contentType);
        end
        
        request_struct = mixInStruct( request_struct, query_struct );
        request_struct = mixInStruct( request_struct, tokenNames );
        
        try
          response = fHandle(request_struct);
        catch err
          if strfind(err.identifier, 'http') == 1
            % Already restful.
            rethrow(err);
          end
          % Cast to restful exception.
          error('http400:Bad_Request', '%s', err.message);
        end
        
        if isstruct(response) && isfield(response, 'contentType')
          responseContentType = response.contentType;
        else
          responseContentType = contentType;
        end
        
        if ~isstruct(response)
          response = num2str( response );
          responseContentType = 'text/plain';
        elseif strcmp(responseContentType, 'application/x-www-form-urlencoded')
          response = XWWWForm_stringify( response );
        elseif strcmp(responseContentType, 'multipart/form-data')
          [response, boundary] = MultiPart_stringify( response );
          responseContentType = sprintf('%s; boundary=%s', responseContentType, boundary);
        elseif isfield(response, 'body')
          response = response.body;
        else
          error('http400:Bad_Request', 'Invalid Content-Type: %s', contentType);
        end
        
        status = '200 OK';
        return;
     end
    end
    
    response = [];
    status = '405 Method Not Allowed';
    responseContentType = 'text/plain';

  end

  function RestRouterSansException(requestMethod_str, requestUrl_str, requestBody_str, contentType)
    
    try
      [status, responseBody, responseContentType] = RestRouter(requestMethod_str, requestUrl_str, ...
        requestBody_str, contentType);
    catch err
      if strfind(err.identifier, 'http') == 1
        % This was a restfull exception, retrieve the status code
        status = regexprep(err.identifier(5:end), ':|_', ' ');
      else
        status = '500 Internal Server Error';
      end
      % Get around the brain dead 'user friendly' error messages
      % see http://support.microsoft.com/kb/294807
      responseBody = sprintf('%s%s', err.message, repmat(' ', 1, 513));
      responseContentType = 'text/plain';
      fprintf('%s\n', getReport(err,'extended'));
    end

    fprintf('status %s\n%s\n', status, responseBody);
    
    serverObj.responseStatus = java.lang.String(status);
    if isempty(responseBody)
      serverObj.responseBody = [];
    else
      serverObj.responseBody = java.lang.String(responseBody);
    end
    
    serverObj.responseContentType = java.lang.String(responseContentType);

  end
  
  
  function listen()
    if isdeployed
      % Standalone application
      while serverObj.waitForRequest()
        RestRouterSansException(char(serverObj.method), char(serverObj.uri), ...
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
  NuServerJavaProxy(@RestRouterSansException);
  
  server = struct();
  server.listen = @listen;
  server.stop = @stop;

end