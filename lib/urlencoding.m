function u = urlencoding(s)
%u = urlencoding(s) converts a string into URL encoding representation.
%
% Source: http://rosettacode.org/wiki/URL_encoding
%
% Example:
%   urlencoding('http://foo bar/') -> http%3A%2F%2Ffoo%20bar%2F

  u = '';
  for k = 1:length(s),
      if isalnum(s(k))
        u(end+1) = s(k);
      else
        u=[u,'%',dec2hex(s(k)+0)];
      end;     
  end
end