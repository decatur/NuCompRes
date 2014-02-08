function response = EdgeDetectorResource( request )

  % Sobel edge filter
  s = [1 2 1; 0 0 0; -1 -2 -1];

  dim = JSON_parse(char(request.dim));
  assert( dim.height*dim.width == length(request.data));

  M = double(reshape(request.data, dim.width, dim.height)).';
  % Note: Convolusion increases width and height of M by 2 pixels
  M = conv2(M, s);
  % For debugging:
  %image(M); axis image
  
  response.data = int8(reshape(M.', 1, numel(M)));
  dim = struct('height', size(M, 1), 'width', size(M, 2));
  response.dim = JSON_stringify(dim);
  
end


