function cellvec = expandcells(cellvec);
    % Expands vectors of cells with sub-cells into single cell vector
    % of non-cell elements. Useful for passing variable-length series of 
    % arguments between functions. 

    % Main
    cellarglocs = find(cellfun(@iscell,cellvec));
    contains_subcells = true;
    while contains_subcells
        for jj=1:length(cellarglocs)
            cellvec = [cellvec(1:cellarglocs(jj-1)) ...
                        cellvec{cellarglocs(jj)} ...
                        cellvec(cellarglocs(jj+1):end)];
                % expand cell elements onto end, in order.
        end
        cellarglocs = find(cellfun(@iscell,cellvec));
        if isempty(cellarglocs); contains_subcells = false; end
    end
end
