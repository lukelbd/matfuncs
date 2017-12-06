function [ x ] = dimmean( x, dims )
    % Gets mean along multiple dimensions
    dims = dims(:);
    assert(all(floor(dims)==dims),'Dimension ids must be integer.');
    for ii=1:numel(dims)
        x = mean(x,dims(ii));
    end
