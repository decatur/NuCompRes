function c = mixInStruct( a, b )
    c = a;
    for field = fieldnames( b)'
      c.( field{ 1}) = b.( field{ 1});
    end
  end