function [ x ] = normalize( x )
    % Just normalized arrays.
    % Usage: [ x ] = normalize( x )
    % [ x, range ] = normalize( x ) 
    %   -x is fixed data
    %   -optionally returns range (min and max) for use with unnormalize
    
    range = [min(x(:)) max(x(:))];
    x = (x-range(1))/(range(2)-range(1));
