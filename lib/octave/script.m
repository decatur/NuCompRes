
if length(argv) == 1
  port = str2double(argv(){1});
else
  port = 8080;
end

addpath('resources;lib;lib/octave;support/json;support/d3;examples');

server = startMyServer(port);

