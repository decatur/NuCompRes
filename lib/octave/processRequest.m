function stopped = processRequest(routingTable, sock)
%processRequest() parses and dispatches a HTTP/1.1 request.  
% See http://tools.ietf.org/html/rfc2616

bufferSize = 0xfff;

[clientSocket, clientInfo] = accept(sock);

clientInfo

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
    sprintf('%d: %s', count, char(data))
    req = sprintf('%s%s', req, char(data));
    length(req)
    contentLength
    
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
                tokens = regexp(headers{j}, '^([^:]+):(.*)$', 'tokens');
                headerStruct.(strrep(tokens{1}{1}, '-', '')) = tokens{1}{2};
            end
            
            sprintf('Headers ..............')
            headerStruct
            
            if isfield( headerStruct, 'ContentLength' )
                contentLength = str2num(headerStruct.ContentLength);
            end
            
            if isempty(contentLength) || contentLength == 0
                % No request body.
                % TODO: 411 (length required) 
                sprintf('No request body.');
                break;
            end
            
            sprintf('contentLength: %d', contentLength)
            sprintf('req: %d foo: %d', length(req), contentLength + index + 3)
            
            % TODO: Reject reuests with any Content-Encoding header.
        end
    end
    
    if ~isempty(contentLength) &&  length(req) == contentLength + index + 3
        requestBody = req((index + 4):end);
        break;
    end
    %else
        % TODO: When is this the case?
    %    break;
    %end
end

if strcmp(uri, '/favicon.ico')
	stopped = false;
	return;
end

sprintf("%s\n%s", strftime("%Y-%m-%d", localtime(time())), req)

if isfield(headerStruct, 'ContentType')
    contentTypeHeader = headerStruct.ContentType;
else
    contentTypeHeader = [];
end

response = RestRouterSansException(routingTable, method, uri, requestBody, contentTypeHeader);

msg = sprintf('HTTP/1.1 %s\r\n', response.status);

if length(response.body) > 0
    msg = sprintf('%sContent-Type: %s\r\nContent-Length: %d\r\n\r\n%s', msg, response.contentType, length(response.body), response.body);
    % TODO: Send Server: NuCompRes-Server/0.1.0
end

msg

send(clientSocket, msg);
disconnect(clientSocket);

stopped = ( strcmp(method, 'POST') && strcmp(uri, '/admin/stop') );

end