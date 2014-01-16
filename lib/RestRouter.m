function response = RestRouter(routingTable, requestMethod, requestUrl, requestBody, contentTypeHeader)

    response = struct();

    fprintf(1, '%s %s %s\n%s\n', requestMethod, requestUrl, contentTypeHeader, requestBody);
    %%keyboard();
    if ~isempty(contentTypeHeader)
      [contentType, contentTypeParams] = HeaderValue_parse(contentTypeHeader);
    else
      contentType = 'text/plain';
    end
    
    % Example requestUrl: '/foo/:id?arg=3
    tok = regexp(requestUrl, '^([^?]*)(\?.*)?$', 'tokens');
    
    % /foo/:id?arg=3 -> path = /foo/:id; query = ?arg=3
    path = tok{1}{1};
    % 
    if length(tok{1}) == 2  % Octave bug; MATLAB yields an empty second entry.
        query = tok{1}{2};
    else
        query = {};
    end
    
    if ~isempty(query)
      query_struct = querystring_parse(query(2:end));
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
 
      [match, tokenNames] = regexp(requestAction, routeAction, 'match', 'names');

      if ~isempty(match)
        fHandle = route{2};
        
        if strcmp(contentType, 'application/x-www-form-urlencoded')
          request_struct = querystring_parse(requestBody);
        elseif strcmp(contentType, 'multipart/form-data')
          request_struct = MultiPart_parse(requestBody, contentTypeParams.boundary);
        elseif strcmp(contentType, 'text/plain')
          request_struct = struct();
          request_struct.body = requestBody;
        else
          error('http400:Bad_Request', 'Invalid Content-Type: %s', contentType);
        end
        
        request_struct = mixInStruct( request_struct, query_struct );
        request_struct = mixInStruct( request_struct, tokenNames );
        
        try
          handlerResponse = fHandle(request_struct);
        catch % err  % the MATLAB way
          err = lasterror(); % Octave bug
          if strfind(err.identifier, 'http') == 1
            % Already restful.
            rethrow(err);
          end
          % Cast to restful exception.
          error('http400:Bad_Request', '%s', err.message);
        end
        
        if isstruct(handlerResponse) && isfield(handlerResponse, 'contentType')
          response.contentType = handlerResponse.contentType;
        else
          response.contentType = 'application/json'; %'multipart/form-data';
        end
        
        if strcmp(response.contentType, 'application/json') || ~isstruct(handlerResponse)
          response.body = JSON_stringify( handlerResponse, [], 4 );
          response.contentType = 'application/json';
        elseif strcmp(response.contentType, 'application/x-www-form-urlencoded')
          response.body = querystring_stringify( handlerResponse );
        elseif strcmp(response.contentType, 'multipart/form-data')
          [response.body, boundary] = MultiPart_stringify( handlerResponse );
          response.contentType = sprintf('%s; boundary=%s', response.contentType, boundary);
        elseif isfield(handlerResponse, 'body')
          response.body = handlerResponse.body;
        else
          error('http400:Bad_Request', 'Invalid Content-Type: %s', contentType);
        end
        
        response.status = '200 OK';
        return;
     end
    end
    
    response.status = '405 Method Not Allowed';
    response.contentType = 'text/plain';
    response.body = response.status;

  end