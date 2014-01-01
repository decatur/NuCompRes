function server = myServer(port)
%myServer demonstrates how to build a routing table and start the server.  

% Cast port to number in case this is called from the command line.
if (ischar(port)), port = str2double(port); end;

aop = american_option_pricer();

routingTable = {};
routingTable{end+1} = {'GET /docs/:filename', @FileResource};
routingTable{end+1} = {'POST /eval', @EvalResource};
routingTable{end+1} = {'POST /pricer/options/american', aop.exec};
routingTable{end+1} = {'PUT /pricer/options/american/config', aop.setConfig};
% Alias to the more REST-ish PUT, but POST is supported by HTML forms.
routingTable{end+1} = {'POST /pricer/options/american/config', aop.setConfig};
% Dito for GET, but it's realy bad style.
routingTable{end+1} = {'GET /pricer/options/american/config', aop.getConfig};
routingTable{end+1} = {'POST /admin/stop', @StopResource};

if exist('octave_config_info')
    server = NuServerOctave(port, routingTable);
else
    server = NuServer(port, routingTable);
end

fprintf(1, 'Visit http://localhost:%d/docs/index.html\n', port);

end
