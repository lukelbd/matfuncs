function [ result ] = myget( hs, field )
    % Gets argument "field" from UserData structure (case-insensitive), and gets 'Position' property in "inches" (if hggroup, gets multiple positions
    % and concatenates them into array of size [NumChildren 4])
    % Usage: [ Value ] = myget( hs, Name )
    %   hs -- Array of handles. 
    %   Name -- Fieldname, string (case-insensitive)
    %   Value -- Result; if hs non-scalar, cell-array of results with dimensions matching size(hs)
    %
    % NOTE this is generalized to give arbitrary array output for hs, but better to output graphics objeects all in vectors
%    isobject(hs), field
    assert(all(isobject(hs(:))) && ischar(field),'myget:Bad input. Arg1 must be object handle array, followed by string field name.');
    hsz = size(hs); hs = hs(:);
    result = cell(length(hs),1);
    for ih=1:length(hs)
        % special considerations if field is "position"
        switch lower(field)
        case 'position'
        %% Position of object or sub-objects (used when re-shuffling objects)
            tp = get(hs(ih),'Type');
            switch tp
            case 'hggroup'
                ch = get(hs(ih),'Children');
            otherwise
                ch = hs(ih);
            end
            % type
            assert(any(strcmpi(get(ch(1),'Type'),{'axes','text','figure'})),'Object/object group does not have "Position" property.');
            oldunits = get(ch,'Units'); if ~iscell(oldunits); oldunits = {oldunits}; end
            set(ch,'Units','inches');
            pos = get(ch,'Position');
            if iscell(pos); pos = cat(1,pos{:}); end
            result{ih} = pos;
            for ich=1:numel(ch); 
                set(ch(ich),'Units',oldunits{ich}); 
            end
        otherwise
        %% Field stored in UserData (case insensitive match)
            hInfo = get(hs(ih),'UserData');
            fields = fieldnames(hInfo); % result is always cell array, even if singleton
            fieldfind = cellfun(@(x)strcmpi(x,field),fields);
            if ~any(fieldfind); error('Field "%s" does not exist.',field); end
            % retrieve
            result{ih} = hInfo.(fields{fieldfind});
        end
    end
    % output
    result = reshape(result,hsz);
    if numel(result)==1; result = result{1}; end
