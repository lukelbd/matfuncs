function [ array ] = floorto(array, num)
    % Rounds up numbers in <array> to nearest fraction (in multiples from zero) <num>
    % Usage: array = ceilto(array, num)

    %% Input
    assert(nargin==2,'Bad input.');
    assert(isscalar(num),'Rounding number must be scalar.');
    %% Run
    array = ceil((1/num)*array)*num;
