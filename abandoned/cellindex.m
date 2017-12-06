function [ newcells ] = cellindex( cells, arr1, arr2 );
    % Quick little function for transplanting data from nested cells
    % into a cell vector based on array indices
    %
    % Input: [ newcells ] = cell_retrieve( cells, arr1, arr2):
    % cells - 2-level-deep nested cell array
    % arr1 - indices for first level of array
    % arr2 = indices for second level of array

    if length(arr1)~=length(arr2)
        error('Id vectors should have same length.')
    end
    N = length(arr1);

    newcells = cell(1,N);
    for k=1:N
        newcells{k} = cells{arr1(k)}{arr2(k)};
    end

end
