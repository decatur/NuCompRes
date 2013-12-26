function NuServerJavaProxy(requestMethod_str, requestUrl_str, requestBody_str, contentType)
% Wolfgang Kühn 2013-11-29

  persistent callback

  if nargin == 1
    callback = requestMethod_str;
    return;
  end
    
  callback(requestMethod_str, requestUrl_str, requestBody_str, contentType);

end

