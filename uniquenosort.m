function [ un ] = uniquenosort( v )
    % Gets unique elements without sorting
    
    % Parse
    assert(nargs==1,'Wrong number of input arguments.');
    assert(isnumeric(v) && isvector(v));
    % Get elements
    ii = 1;
    while ii<=length(v)
        repids = (v(ii)==v);
        v(repids) = [];
        ii = ii+1;
    end
    % Output
    un = v;

end

