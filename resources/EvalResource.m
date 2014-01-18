function response = EvalResource( request )

  response = struct;
  eval( request.expression );
  
end



