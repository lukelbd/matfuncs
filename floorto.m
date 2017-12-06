function [ array ] = floorto(array, num)
    % Rounds down numbers in <array> to nearest fraction (in multiples from zero) <num>
    % Usage: array = floorto(array, num)

    %% Input
    assert(nargin==2,'Bad input.');
    assert(isscalar(num),'Rounding number must be scalar.');
    %% Run
    array = floor((1/num)*array)*num;
