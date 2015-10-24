fid = fopen ('multipart_request.txt', 'rb');
body = fread(fid, Inf, '*int8').';
fclose(fid);

boundary = '----WebKitFormBoundarysLNm0BrLwezNds8h';
boundary = sprintf('\r\n--%s', boundary);
boundary = int8(0+boundary);

idx = findPattern2(body, boundary)

part = body(idx(1):idx(2)-1);

subIdx = findPattern2(part, [13 10])
headers = char(part(subIdx(2)+2:subIdx(4)-2))
content = part(subIdx(4)+2:end)

req=MultiPart_parse(body, '----WebKitFormBoundarysLNm0BrLwezNds8h')