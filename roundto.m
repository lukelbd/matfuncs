function [ array ] = roundto(num, array)
    % Rounds numbers in <array> to nearest fraction <num>
    % Usage: array = roundto(num, array)

    %% Input
    assert(nargin==2,'Bad input.');
    assert(isscalar(num),'Rounding number must be scalar.');
    %% Run
    array = round((1/num)*array)*num;
