// <path-to-node>/bin/node nodejs-client.js myremotehost 8080 "response=1+1"

var http = require('http');

// The command line arguments
var host = process.argv[2],
    port = process.argv[3],
    matlabCode = process.argv[4];

var options = {
  host: host,
  path: '/eval',
  port: port,
  method: 'POST',
  headers: {'Content-Type': 'application/json'}
};

callback = function(response) {
  var str = ''
  response.on('data', function (chunk) {
    str += chunk;
  });

  response.on('end', function () {
    console.log(str);
  });
}

var requestObject = {
    expression: matlabCode
};

var req = http.request(options, callback);
req.write( JSON.stringify(requestObject) );
req.end();