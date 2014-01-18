addpath('support/json;test;test/json');

assertEquals(JSON_parse('[1, 2]'), [1 2]);
assertEquals(JSON_parse('[[1, 2], [3, 4]]'), [1 2;3 4]);

mExpect = [];
mExpect(1,:,:)=[1 2;3 4];
mExpect(2,:,:)=[5 6;7 8];

mAct = JSON_parse('[[[1,2],[3,4]],[[5,6],[7,8]]]');
assertEquals(mExpect, mAct);

mAct = JSON_parse(readFileToString('3dim.json', 'utf-8'));
assertEquals(mExpect, mAct);

assertEquals(JSON_parse('[1, null, 2]'), [1 NaN 2]);

s = JSON_parse('{"foo":"Hello", "bar":1}', @(obj, key, value) class(value));
assertEquals(s, struct('foo', 'char', 'bar', 'double'));

sExpect = struct();
sAct = JSON_parse('{}');
assertEquals(sExpect, sAct);

sAct = JSON_parse(' {}');
assertEquals(sExpect, sAct);

assertEquals(JSON_parse('true'), true);

assertEquals(JSON_parse('false'), false);

assert(strcmp(JSON_parse('"foo"'), 'foo'));

cExpect = {1 5 'false'};
cAct = JSON_parse('[1, 5, "false"]');
assertEquals(cAct, cExpect);

assertEquals(JSON_parse('null'), []);
    
assertEquals(JSON_parse('1 '), 1);

assertEquals(JSON_parse('"f\u0153\u0153bar"'), 'fœœbar');

try
  JSON_parse('1.00000000000000000000000000000000000000a');
  assert(false);
catch my_caught_error
  assertEquals(my_caught_error.message, 'Unexpected char at position 41: 000000000000000<error>a');
end

try
  JSON_parse(sprintf('"foo\nbar'));
  assert(false);
catch my_caught_error
  assertEquals(my_caught_error.message, sprintf('Not a valid string character at 5: "foo<error>\nbar'));
end

oAct = JSON_parse(readFileToString('pass1.json', 'utf-8'));
