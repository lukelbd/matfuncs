function [ bool ] = isproperty(h, field)
    % Tests whether field or specified fields are properties in UserData structure.
    % Analagous to isfield for structure, this tests the structure in stored UserData for object(s) h
    %
    % Usage: [ bool ] = isproperty(h, field)
    %   h -- object handle or handles
    %   field -- string or cell-array of strings we want to test
    %   bool -- Boolean array of size [NumHandles NumFields]
    %
    h = h(:); if ischar(field); field = {field}; end; field = field(:);
    bool = zeros(numel(h),numel(field))==1;
    if ~isstruct(s); return; end
    for ih=1:numel(h);
        fnames = get(h(ih),'UserData');
        for fi=1:numel(field)
            if any(strcmpi(field{fi},fnames)); % remember field is cell-array of fields
                bool(ih,fi) = true;
            end
        end
    end
