function [ x ] = unnormalize( x, range )
    % Un-normalizes data onto original minimum and maximum.
    % Usage: [ x ] = unnormalize( x, range )
    %   -"range" is length-2 vector with minimum and maximum
    %   -x is fixed data
    
    assert(nargin==2,'Bad input; must include range [min max] as second arg.');
    assert(numel(range)==2,'Bad range; must be length-2 vector.');
    assert(range(2)>range(1),'Bad range; second element must be greater.');
    x = range(1) + (range(2)-range(1))*x;
