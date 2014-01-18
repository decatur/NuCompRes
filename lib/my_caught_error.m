function my_caught_error
% This is a workaround for the Matlab vs. Octave incompatibility with
% respect to catching errors. It avoids using lasterror in Matlab:
% It is deprecated, and its err.message is messed up (2012R2).
% See http://lists.gnu.org/archive/html/octave-bug-tracker/2011-05/msg00009.html
  assignin('caller', 'my_caught_error', lasterror);

end

