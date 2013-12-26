function response_struct = EvalResource( request_struct )

  response_struct = struct;
  response_struct.result = eval( request_struct.expression );

end



