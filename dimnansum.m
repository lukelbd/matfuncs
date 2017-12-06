function [ x ] = dimnansum( x, dims )
    % Gets nansum along multiple dimensions
    dims = dims(:);
    assert(all(floor(dims)==dims),'Dimension ids must be integer.');
    for ii=1:numel(dims)
        x = nansum(x,dims(ii));
    end
