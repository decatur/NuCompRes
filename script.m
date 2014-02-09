
if length(argv) == 1
  port = str2double(argv(){1});
else
  port = 8080;
end

addpath('resources;lib;support/json;support/d3;examples');
javaaddpath('lib');
server = startMyServer(port);

