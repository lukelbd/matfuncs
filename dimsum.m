function [ x ] = dimsum( x, dims )
    % Gets sum along multiple dimensions
    dims = dims(:);
    assert(all(floor(dims)==dims),'Dimension ids must be integer.');
    for ii=1:numel(dims)
        x = sum(x,dims(ii));
    end
