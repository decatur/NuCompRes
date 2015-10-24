addpath('test;lib');

[n, v] = Header_parse('Content-Type: multipart/form-data; boundary=--7dd2cf1103dc');
assertEquals( n, 'content_type' );
assertEquals( v, 'multipart/form-data; boundary=--7dd2cf1103dc' );

elements = HeaderValue_parse( 'multipart/form-data; boundary=--7dd2cf1103dc' );
assertEquals( elements{1}.value, 'multipart/form-data' );
assertEquals( elements{1}.params, struct('boundary', '--7dd2cf1103dc') );

elements = HeaderValue_parse( 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' );
assertEquals( elements{1}.value, 'text/html' );
assertEquals( elements{2}.value, 'application/xhtml+xml' );
assertEquals( elements{3}.value, 'application/xml' );
assertEquals( elements{3}.params, struct('q', '0.9') );
assertEquals( elements{4}.value, '*/*' );
assertEquals( elements{4}.params, struct('q', '0.8') );

o = struct;
o.foo = 1;
o.bar = 'foo&bar';

% Test XWWWForm
s = querystring_stringify(o);
assertEquals( s, 'foo=1&bar=foo%26bar' );
o1 = querystring_parse(s);
assertEquals( o, o1 );

% Test MultiPart
[s, boundary] = MultiPart_stringify(o);
o1 = MultiPart_parse(s, boundary);
assertEquals( o, o1 );

% Empty message
o = struct;

% Test XWWWForm
s = querystring_stringify(o);
assertEquals(s, '');
o1 = querystring_parse(s);
assertEquals( o, o1 );

% Test MultiPart
[s, boundary] = MultiPart_stringify(o);
o1 = MultiPart_parse(s, boundary);
assertEquals( o, o1 );
