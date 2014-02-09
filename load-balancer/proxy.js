/*
 * Simple load balancing node.js proxy. Dispatches request to port 8080
 * to the servers listening on ports 9000 and 9001.
 *
 * Based on http://www.catonmat.net/http-proxy-in-nodejs/
 * TODO: Update according https://gist.github.com/e0ne/3156463
 * TODO: Use https://github.com/nodejitsu/node-http-proxy, https://mazira.com/blog/introduction-load-balancing-nodejs/
 */

var http = require('http');

var proxyPort = 8080,
    servers = [
        { host:'127.0.0.1', port:9000 }, { host: '127.0.0.1', port:9001 }//, etc.
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
      host: server.host,
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