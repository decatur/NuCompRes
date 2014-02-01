function weights = HeaderValueWeights( provided, acceptHeader )
%HeaderValueWeights returns the weight of the provided values.
%
% See See http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
%
% Example:  
%  FindMostSignificantValue({'image/jpeg', 'application/x-ms-application'}, 'application/x-ms-application, image/jpeg;q=0.5, application/xaml+xml')
%  ->  [0.5 1.0]
%
% Copyright@ 2014 Wolfgang Kuehn

requestedValues = HeaderValue_parse(acceptHeader);
weights = zeros(1, length(provided));

for i=1:length(requestedValues)
  value = requestedValues{i}.value;
  index = find(ismember(provided, value));
  if ~isempty(index)
    if isfield(requestedValues{i}.params, 'q')
      weights(index) = str2double(requestedValues{i}.params.q);
    else
      weights(index) = 1;
    end
  end
end

end

