# Load balancing

This simple load balancing server is written for [Node.js](http://nodejs.org/).
It acts as a [reverse http proxy](http://en.wikipedia.org/wiki/Reverse_proxy).

1. Start NuCompRes-Servers on port 9000 and 9001. 
2. Start the load balancing proxy.
3. Now issue (for example with the html5 sample client) several sleep requests
    
    sleep(1);
    response.x = 'Done'

The proxy will then log

    Listening on 8080
    Dispatching to [ { port: 9000 }, { port: 9001 } ]
    Thu, 30 Jan 2014 21:03:07 GMT POST /eval -> 9000
    Thu, 30 Jan 2014 21:03:08 GMT POST /eval -> 9001
    Thu, 30 Jan 2014 21:03:08 GMT POST /eval -> 9000
    Thu, 30 Jan 2014 21:03:08 GMT POST /eval -> 9000
    Thu, 30 Jan 2014 21:03:09 GMT POST /eval -> 9001
    Thu, 30 Jan 2014 21:03:11 GMT POST /eval -> 9000