function [ x ] = flat( x )
    % Just gets flat version of x; sometimes want to flatten result of
    % some operation, and can't use the array notation.
    % Result: x = x(:);
    x = x(:);
