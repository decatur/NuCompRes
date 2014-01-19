function u = urldecoding(s)
% Example:
%   urldecoding('http%3A%2F%2Ffoo%20bar%2F') -> http://foo bar/
%
% Copyright@ 2013 Wolfgang Kuehn
% Submitted to http://rosettacode.org/wiki/URL_decoding#MATLAB_.2F_Octave
% TODO: Submitted with k+3 <= length(s) bug!

	u = '';
  k = 1;
	while k<=length(s)
    if s(k) == '%' && k+2 <= length(s)
        u = sprintf('%s%c', u, char(hex2dec(s((k+1):(k+2)))));
        k = k + 3;
    else
        u = sprintf('%s%c', u, s(k));
        k = k + 1;
    end 
	end
end