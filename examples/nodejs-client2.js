/*
 * Simple Node.js script to query the eval-resource from a command line.
 *
 * Usage:
 *  <path-to-node>/bin/node nodejs-client.js myremotehost 8080 "response=1+1"
 */

var FormData = require('form-data');
var fs = require('fs');

var form = new FormData();
form.append('expression', 'response.x=1+1;');
form.append('my_buffer', new Buffer(10));
//form.append('my_file', fs.createReadStream('/foo/bar.jpg'));

form.submit('http://localhost:8080/eval', function(err, response) {
  if ( err ) {
    console.log(err);
    return;
  }
  var str = ''
  response.on('data', function (chunk) {
    str += chunk;
  });

  response.on('end', function () {
    console.log(str);
  });
});
