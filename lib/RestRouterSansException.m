function response = RestRouterSansException(routingTable, requestMethod, requestUrl, requestBody, requestHeaders)

    try
      response = RestRouter(routingTable, requestMethod, requestUrl, ...
        requestBody, requestHeaders);
    catch my_caught_error % Octave workaround
      err = my_caught_error;
      response = struct();
      
      if strfind(err.identifier, 'http') == 1
        % This was a restfull exception, retrieve the status code
        response.status = regexprep(err.identifier(5:end), ':|_', ' ');
      else
        response.status = '500 Internal Server Error';
      end
      % Get around the brain dead 'user friendly' error messages
      % see http://support.microsoft.com/kb/294807
      response.body = sprintf('%s%s', err.message, repmat(' ', 1, 513));
      response.contentType = 'text/plain';
      if exist('getReport')
        fprintf(1, '%s\n', getReport(err,'extended'));
      end
    end

    % fprintf(1, 'status %s\n%s\n', response.status, response.body);

  end