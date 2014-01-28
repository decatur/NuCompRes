addpath('support/json;test');

source('support/json/JSON_stringify.m');

assertEquals(JSON_stringify(['foo' 'bar']), '"foobar"');

assertEquals(JSON_stringify(1), 1);

assertEquals(JSON_stringify(1/3), '0.3333333333');

assertEquals(JSON_stringify(struct('a', 1)), '{"a":1}');

complexMatrix =  [[1+i 1-i]; [-i i]];
JSON_stringify(struct('real', real(complexMatrix), 'imag', imag(complexMatrix)));

assertEquals(JSON_stringify([1 1i]), '[1, null]');

assertEquals(JSON_stringify([true false]), '[true,false]');
assertEquals(JSON_stringify([1 true false]), '[1,1,0]');

s = struct('a', 1.5, 'b', 'foo');
s.foo = s;

JSON_stringify(s, [], sprintf('\t'))

m=[1 2];
assertEquals(JSON_stringify(m), '[1,2]');

assertEquals(JSON_stringify(m.'), '[[1],[2]]');

m=[1 2;3 4];
assertEquals(JSON_stringify(m), '[[1,2],[3,4]]');

assertEquals(JSON_stringify(m, [], 4), '[[1,2],[3,4]]');

assertEquals(JSON_stringify(struct('foo', m), [], 4), '[[1,2],[3,4]]');

JSON_stringify(m, [], sprintf('\t'))

m=[];
m(1,:,:)=[1 2;3 4];
m(2,:,:)=[5 6;7 8];

assertEquals(JSON_stringify(m), '[[[1,2],[3,4]],[[5,6],[7,8]]]');

assertEquals(JSON_stringify(m, [], 4), readFileToString('3dim.json', 'utf-8'));

m = [1 NaN 2];
assertEquals(JSON_stringify(m), '[1,null,2]');

s = struct();
s.m=m;
JSON_stringify(s, [], sprintf('\t'))

c = {1 2};
assertEquals(JSON_stringify(c), '[1,2]');

assertEquals(JSON_stringify(c'), '[[1],[2]]');

c = {1 2;3 4};
assertEquals(JSON_stringify(c), '[[1,2],[3,4]]');
assertEquals(JSON_stringify(c, [], 4), '[[1,2],[3,4]]');

s=struct();
s.foo = c;
assertEquals(JSON_stringify(s, [], 4), '[[1,2],[3,4]]');

assertEquals(JSON_stringify(struct()), '{}');
assertEquals(JSON_stringify(true), 'true');
assertEquals(JSON_stringify('foo'), '"foo"');
assertEquals(JSON_stringify({1, 'false', false}), '[1,"false",false]');
assertEquals(JSON_stringify(struct('x', 5)), '{"x":5}');
assertEquals(JSON_stringify(struct('x', 5, 'y', 6)), '{"x":5,"y":6}');

assertEquals(JSON_stringify(sprintf('foo\n\r\t')), '"foo\n\r\t"');

assertEquals(JSON_stringify('fœœbar'), '"fœœbar"');


% Test struct array
s = struct('foo', {1 2});
assertEquals(JSON_stringify(s), '[{"foo":1},{"foo":2}]');

oAct=JSON_parse(readFileToString('pass1.json', 'utf-8'));
writeStringToFile('pass1.json', JSON_stringify(oAct,[],4), 'UTF-8');

% Performance
m=ones(1, 1000);
tic
JSON_stringify(m);
toc
tic
JSON_stringify(m');
toc
