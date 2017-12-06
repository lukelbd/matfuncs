function [ res ] = range( array )
    % Very simple: returns [min(array(:)) max(array(:))]
    res = [min(array(:)) max(array(:))];
