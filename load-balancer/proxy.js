/*
 * Simple load balancing node.js proxy. Dispatches request to port 8080
 * to the servers listening on ports 9000 and 9001.
 *
 * Based on http://www.catonmat.net/http-proxy-in-nodejs/
 */

var http = require('http');

var proxyPort = 8080,
    servers = [
        { port:9000 }, { port:9001 }//, { port:9002 }, etc.
    ];


console.log('Listening on', proxyPort);
console.log('Dispatching to', servers);

var mostRecentServer;

http.createServer(function(request, response) {
  var now = new Date();

  var i, server;
  
  for ( i=0; i<servers.length; i++ ) {
    server = servers[i];
    if ( server.bussy !== true ) break;
  }
  
  // All servers are bussy. Choose the most recent scheduled. 
  if ( i==servers.length ) {
    server = mostRecentServer;
  } else {
    mostRecentServer = server;
  }
 
  server.bussy = true;
  server.lastDispatch = now;
  
  console.log(now.toGMTString(), request.method, request.url, '->', server.port);

  var options = {
      host: '127.0.0.1',
      path: request.url,
      port: server.port,
      method: request.method,
      headers: request.headers
  };

  var proxy_request = http.request(options);
  
  proxy_request.addListener('response', function (proxy_response) {
    
    proxy_response.addListener('data', function(chunk) {
      response.write(chunk, 'binary');
    });
    
    proxy_response.addListener('end', function() {
      response.end();
      server.bussy = false;
    });
    
    response.writeHead(proxy_response.statusCode, proxy_response.headers);
  });
  
  request.addListener('data', function(chunk) {
    proxy_request.write(chunk, 'binary');
  });
  
  request.addListener('end', function() {
    proxy_request.end();
  });
  
}).listen(proxyPort);