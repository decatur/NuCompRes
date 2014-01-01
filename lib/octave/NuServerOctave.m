function server = NuServerOctave(port, routingTable)
%server = NuServerOctave(port, routingTable)
% Copyright© 2013, Wolfgang Kuehn

  server = struct();
  server.start = @() start(port, routingTable);

end

function start(port, routingTable)
backlog = 5;

sock = socket(AF_INET, SOCK_STREAM, 0);
assert( sock ~= -1 );

returnCode = bind(sock, port);
assert(returnCode == 0, 'Socket already bound?');

%On success, zero is returned.
returnCode = listen(sock, backlog);
assert(returnCode == 0, 'TODO: When can this happen');

%i = 1;
while true
    if processRequest(routingTable, sock)
        break;
    end
    %i = i + 1;
end

disconnect(sock);

end