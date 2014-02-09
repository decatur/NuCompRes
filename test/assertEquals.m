function assertEquals( a, b )
%assertEquals assert that two values are equal, treating NaNs as such.
  
  if ~exist('isequaln')
    % Octave bug, but fixed in 3.8.0
    isequaln = @isequalwithequalnans;
  end
  
  assert(isequaln(a, b));
end

