function my_caught_error
% See http://lists.gnu.org/archive/html/octave-bug-tracker/2011-05/msg00009.html
  assignin('caller', 'my_caught_error', lasterror);

end

