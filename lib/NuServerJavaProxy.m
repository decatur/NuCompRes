function NuServerJavaProxy(javaServerObj)
% Copyright@ 2013-2014 Wolfgang Kuehn

  persistent callback

  if isa(javaServerObj, 'function_handle')
    callback = javaServerObj;
    return;
  end
    
  if isempty(callback)
    error('Callback is unset or was reseted');
  end
  
  callback(javaServerObj);

end

