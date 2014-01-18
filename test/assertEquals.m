function assertEquals( a, b )
%assertEquals assert that two values are equal, treating NaNs as such.
  
  if ~exist('isequaln')
    % Octave bug.
    isequaln = @isequalwithequalnans;
  end
  
  assert(isequaln(a, b));
end

