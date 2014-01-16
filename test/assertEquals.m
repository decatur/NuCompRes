function assertEquals( a, b )
%assertEquals assert that two values are equal, treating NaNs as such.

  assert(isequaln(a, b));
end

