function response_struct = EvalResource( request_struct )

  response_struct = struct;

  if isnumeric( request_struct.expression )
    % Pass through
    response_struct.result = request_struct.expression;
  else
    response_struct.result = eval( request_struct.expression );
  end
  
end



