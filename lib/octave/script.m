# cd D:/ws/NuCompRes
# debug_on_error (true);

if length(argv) == 1
  port = str2double(argv(){1});
else
  port = 8080;
end

addpath('lib;lib/octave');
addpath('resources');
addpath('examples');

server = myServer(port);
server.start();
