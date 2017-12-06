function [ res ] = increment( runs, jumps );
    % Produces arbitrary vector increments normalized from 0 to 1
    assert(nargin==2,'Bad input.');
    assert(isvector(jumps) && isvector(runs) && isnumeric(jumps) && isnumeric(runs), 'Bad input.');
    assert(all(runs==floor(runs)),'Runs must be integer.');
    res = 0; % strt = -1*jumps(1);
    N = length(runs);
    for ii=1:N
        strt = res(end);
        res(end+1:end+runs(ii),1) = strt+[jumps(ii):jumps(ii):jumps(ii)*runs(ii)]';
            % so if runs is 1, the vector has length 1
    end
    res = res/res(end);
