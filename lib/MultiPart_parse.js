/* 
 * MultiPart_parse decodes a multipart/form-data encoded string into a named-part-map.
 * For a production grade parser use https://github.com/felixge/node-formidable.
 * See http://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
 *
 * Copyright@ 2013 Wolfgang Kuehn
*/
function MultiPart_parse(body, contentType) {
    // Examples for content types:
    //      multipart/form-data; boundary="----7dd322351017c"; ...
    //      multipart/form-data; boundary=----7dd322351017c; ...
    var m = contentType.match(/boundary=(?:"([^"]+)"|([^;]+))/i);
    
    if ( !m ) {
        throw new Error('Bad content-type header, no multipart boundary');
    }

    var boundary = m[1] || m[2];

    function Header_parse(header) {
        var headerFields = {};
        var matchResult = header.match(/^.*name="([^"]*)"$/);
        if ( matchResult ) headerFields.name = matchResult[1];
        return headerFields;
    }

    // \r\n is part of the boundary.
    var boundary = '\r\n--' + boundary;

    // Prepend what has been stripped by the body parsing mechanism.
    body = '\r\n' + body;

    var parts = body.split(new RegExp(boundary)),
        partsByName = {};

    // First part is a preamble, last part is closing '--'
    for (var i=1; i<parts.length-1; i++) {
      var subparts = parts[i].split('\r\n\r\n');
      var headers = subparts[0].split('\r\n');
      for (var j=1; j<headers.length; j++) {
        var headerFields = Header_parse(headers[j]);
        if ( headerFields.name ) {
            fieldName = headerFields.name;
        }
      }
      
      value = subparts[1];
      
      if ( !isNaN(Number(value)) ) {
        value = Number(value);
      }
      
      partsByName[fieldName] = value;
    }

    return partsByName;
}
