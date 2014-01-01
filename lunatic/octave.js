var res;

var http = require('http'),
    octave = require('child_process').spawn('c:\\programs\\Octave3.6.4_gcc4.6.2\\bin\\octave.exe', ['-i']);

octave.stdout.on('data', function (data) {
    console.log('stdout: ' + data);
    if ( res ) {
        res.writeHead(200, {'Content-Type': 'text/plain'});
        res.write(data);
        res.end();
        res = undefined;
    }
});

octave.on('exit', function (code) {
        console.log('child process exited with code ' + code);
});

var server = http.createServer(function(request, response) {
  var cmd = "sprintf('FOO %s', '" + request.url + "')";
  octave.stdin.write(cmd + '\n');
  console.log(cmd);
  
  res = response;

}).listen(8080);