⚠️ Deprecated. Please consider using MATLAB Production Server or move over to the Python eco system.

# Overview

NuCompRes (Numerical Computational Resources) is a lightweight component to expose
computational MATLAB® or Octave resources over HTTP.

NuCompRes readily turns your MATLAB investment into a server, enabling clients to integrate using the REST
architectural style.

![client-server](images/client-server.png)

# Target

Experienced MATLAB modelers who want to integrate their solution without having to learn about IT middleware.

# Download

Please use git to retrieve a copy of the development branch, or
[download releases](../../releases).

# Features

* Runs inside a MATLAB session
* Runs inside a (compiled) Standalone  Application
* Debug and hot code a running server within the IDE
* Runs on MS-Windows and Linux

# Requirements

* Tested with MATLAB 2012b (Linux, Microsoft Windows 7) and Octave 3.6.4 (Microsoft Windows 7).
* Java Version 5 or higher.
* (Optional) MATLAB Compiler™ to build a Standalone Application.

# Usage

We start the sample server on port 8080 inside the MATLAB IDE or on the Octave prompt:

    cd <PATH_TO_NuCompRes>
    addpath('resources;lib;support/json;support/d3;examples');
    javaaddpath('lib');
    server = startMyServer(8080);

# Web Clients

With the server running on port 8080, open

    http://localhost:8080/docs/index.html

in a web browser. From there you can explore the exposed sample resources.

# Excel Client

There is an Excel Client interacting with some of the resources.

# MATLAB Client
You can communicate with a remote server from inside MATLAB.

**Warning**: If you do this inside a session which is running the server, your session will freeze!

Example
<pre>
>> urlread('http://myremotehost:8080/eval', 'POST', {'expression' 'response=1+1'})
ans =
result=2
</pre> 


# Curl Client
POST the expression `1+1` to the `eval` resource with a content type of multipart/form-data:

<pre style="color:white;background-color:black">
    > curl -F expression="response=1+1" http://myremotehost:8080/eval
    
        ---
        Content-Disposition: form-data; name="result"

        2
        ------
</pre>

# Stop and Restart Server

Inside a MATLAB session, you may stop

    server.stop()

and restart

    server.start()

a server at any time. To stop a server in a standalone application, issue a `POST /admin/stop`. This will also terminate the application.

# Provided Example Resources

Function myServer() exposes these sample resources

####POST /eval
Evaluate any expression using the eval() function

####GET /docs/:filename
Get a file from the MATLAB path

####POST /pricer/options/american
Price an american option

####PUT /pricer/options/american/config
Configure the option pricer

#### GET /pricer/options/american/config
Get the option pricer configuration

#### POST /admin/stop
Stop the server

# About the Option Pricer Example
The American option pricer is implemented within one MATLAB file. We used closures with nested functions and function handles
to hold state (the pricer configuration) without using the global workspace.
You may or may not follow this pattern. But please consider that the server may eventually hold a couple of resources.
You should separate them well, both data and the functionality.

# Provide Your Own Resource: The Routing
Routing maps the tuple of HTTP-method and URL-path to a MATLAB resource. The path may have named placeholders.
For example

    {'GET /docs/:filename', @FileResource}
    
assigns the FileResource functions to requests such as `GET /docs/myresources.html`. Here myresources.html is passed to the 
FileResource function as the _filename_-field of the request structure. URL query parameters are not part of the routing, so
the request

    GET /docs/myresources.html?foo=bar
    
does the same thing as the previous example, but additionally passes _bar_ as the value of the _foo_ field in the request structure.

To build meaningful routing tables you should eventually become familiar with the [REST](http://en.wikipedia.org/wiki/Representational_state_transfer) architectural style. 

# Content Negotiation
If you send a request to the server, you have to include a content type header. Many clients will do this for you.
Supported types are
* text/plain
* multipart/form-data
* application/x-www-form-urlencoded

TODO: Describe the reponse content type.

If the content type is text/plain or is missing, the server will pass the raw (unparsed) body to the resource as the *request.body* field.

# Hot Code and Debugging
All MATLAB code can be debugged and changed while the server is running.
If you change and compile the Java code, please restart the MATLAB session to flush all Java related caches.

# Load Balancing

Any MATLAB or Octave session is single threaded. So each NuCompRes-Server can only handle one
request at a time. If you want to serve several request simultaneously, then put a proxy server
in front of those NuCompRes-Servers. This proxy then dispatches requests to an idle NuCompRes-Server.

You find a simple [load balancing server](load-balancer/balancing.md) in this project. 

# Into the Wild
NuComRes does not play in the league of production grade load balancing and security (authentication).
A reverse proxy such as [Nginx](http://wiki.nginx.org/Main) can handle these issues.

**Do not**, ever, place a NuComRes server directly in an untrusted zone.

# Code Base
NuCompRes is completely written in MATLAB code. Only a very small, single class Java-Proxy must be incorporated.
No external libraries are required.

# Compiling a MATLAB Standalone Application

For this you need a license for the MATLAB Compiler.

    mcc -I resources -I lib -I examples -a lib/JavaNuServer.class -a examples/myresources.html -mv myServer.m
    
See [path-management-in-deployed-applications] why the -a option is needed.
Upon successful compilation, start the server from the command line with 

    myServer 8080

# Legal Notes

Carefully read The MathWorks Software License Agreement, in particular Section 5.2.3. Deployment Addendum

> Licensee’s Application may not provide scripting capability
> similar to the capabilities of any of the Programs or provide
> functionality or behavior similar to that of the MATLAB
> command line.
    
Be specific in what resources you deploy, and only deploy Standalone Applications.
Never ever deploy the sample eval-resource. It is for local development and debugging inside a session only,
be it MATLAB or Octave. 

# References
* [path-management-in-deployed-applications]
* [matlabcontrol]
* [Calling Matlab from Java](http://www.cs.virginia.edu/~whitehouse/matlab/JavaMatlab.html)

  [path-management-in-deployed-applications]: http://blogs.mathworks.com/loren/2008/08/11/path-management-in-deployed-applications (Path Management in Deployed Applications)
  [matlabcontrol]: https://code.google.com/p/matlabcontrol/ (A Java API to interact with MATLAB)

# Credit Notice
MATLAB® and MATLAB Compiler™ are trademarks or registered trademarks of The MathWorks, Inc.

The American option pricer is taken from [NineWays to Implement the Binomial Method for Option Valuation in MATLAB](http://epubs.siam.org/doi/pdf/10.1137/S0036144501393266)

# License
NuCompRes is licensed under the MIT license.
