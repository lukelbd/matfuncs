function [ x ] = dimnanmean( x, dims )
    % Gets nanmean along multiple dimensions
    dims = dims(:);
    assert(all(floor(dims)==dims),'Dimension ids must be integer.');
    for ii=1:numel(dims)
        x = nanmean(x,dims(ii));
    end
