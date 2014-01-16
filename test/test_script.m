[n, v,p] = Header_parse('Content-Type: multipart/form-data; boundary=--7dd2cf1103dc');
assert( strcmp(n, 'Content-Type') );
assert( strcmp(v, 'multipart/form-data') );
assert( strcmp(p.boundary, '--7dd2cf1103dc') );

o = struct;
o.foo = 1;
o.bar = 'foo&bar';

% Test XWWWForm
s = XWWWForm_stringify(o);
assert(strcmp(s, 'foo=1&bar=foo%26bar'));
o1 = XWWWForm_parse(s);
assert( isequal(o, o1) );

% Test MultiPart
[s, boundary] = MultiPart_stringify(o);
o1 = MultiPart_parse(s, boundary);
assert( isequal(o, o1) );

% Empty message
o = struct;

% Test XWWWForm
s = XWWWForm_stringify(o);
assert(strcmp(s, ''));
o1 = XWWWForm_parse(s);
assert( isequal(o, o1) );

% Test MultiPart
[s, boundary] = MultiPart_stringify(o);
o1 = MultiPart_parse(s, boundary);
assert( isequal(o, o1) );
