
if length(argv) == 1
  port = str2double(argv(){1});
else
  port = 8080;
end

addpath('lib;lib/json;lib/octave;resources;examples');

server = startMyServer(port);

