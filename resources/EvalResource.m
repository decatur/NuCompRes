function res = EvalResource( req )

  res = struct;
  eval( req.expression );
  
end



