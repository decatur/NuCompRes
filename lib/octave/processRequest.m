function stopped = processRequest(routingTable, sock)
%processRequest() parses and dispatches a HTTP/1.1 request.  
% See http://tools.ietf.org/html/rfc2616

bufferSize = 4096;
DEBUG = false;

[clientSocket, clientInfo] = accept(sock);

if DEBUG
  clientInfo
end

headers = {};
headerStruct = struct();
contentLength = [];
req = '';
method = '';
requestBody = [];

while true
    [data, count] = recv(clientSocket, bufferSize);
    
    %count
    
    if count == 0
       % This only happens if client sends no data (there no HTTP), or if connection
       % is closed while blocking. We ignore the request.
       stopped = false;
       return;
    end
    
    %data
    
    %if exist('data', 'var')
    if DEBUG
      sprintf('%d: %s', count, char(data))
    end
    
    req = sprintf('%s%s', req, char(data));
    
    if DEBUG
      length(req)
      contentLength
    end
    
    if isempty(headers)
        index = strfind(req, sprintf('\r\n\r\n'));
        if ~isempty(index)
            index = index(1);
            % All headers have been received.
            % TODO: Merge with MultiPart_parse.
            % TODO. Handle LWS = [CRLF] 1*( SP | HT )
            % TODO: Discard initial empty lines, see http://tools.ietf.org/html/rfc2616#section-4.1
            headers = regexp(req(1:index), sprintf('\r\n'), 'split');
            % First line is the Request-Line: Method SP Request-URI SP HTTP-Version CRLF
            % TODO: Use regexp(..., 'split');
            tokens = regexp(headers{1}, '^(\S+)\s(\S+)\s(\S+)', 'tokens');
            method = tokens{1}{1};
            uri = tokens{1}{2};
            version = tokens{1}{3};
            
            for j=2:length(headers)
                [name, value] = Header_parse(headers{j});
                headerStruct.(name) = value;
            end
            
            if DEBUG
              sprintf('Headers ..............')
              headerStruct
            end
            
            if isfield( headerStruct, 'content_length' )
                contentLength = str2num(headerStruct.content_length);
            end
            
            if isempty(contentLength) || contentLength == 0
                % No request body.
                % TODO: 411 (length required) 
                sprintf('No request body.');
                break;
            end
            
            if DEBUG
              sprintf('contentLength: %d', contentLength)
              sprintf('req: %d foo: %d', length(req), contentLength + index + 3)
            end
            
            % TODO: Reject reuests with any Content-Encoding header.
        end
    end
    
    if ~isempty(contentLength) &&  length(req) == contentLength + index + 3
        requestBody = req((index + 4):end);
        break;
    end

end

if strcmp(uri, '/favicon.ico')
	stopped = false;
	return;
end

if DEBUG
  sprintf('%s\n%s', strftime('%Y-%m-%d', localtime(time())), req)
end

response = RestRouterSansException(routingTable, method, uri, requestBody, headerStruct);

msg = sprintf('HTTP/1.1 %s\r\n', response.status);

if length(response.body) > 0
    msg = sprintf('%sContent-Type: %s\r\nContent-Length: %d\r\n\r\n%s', msg, response.contentType, length(response.body), response.body);
    % TODO: Send Server: NuCompRes-Server/0.1.0
end

if DEBUG
  msg
end

send(clientSocket, msg);
disconnect(clientSocket);

stopped = ( strcmp(method, 'POST') && strcmp(uri, '/admin/stop') );

end