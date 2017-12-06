function [ newflags ] = myset(hs, varargin)
    % Sets arguments in varargin to the UserData structure, and sets 'Position' property using "inches" (if hggroup, sets multiple positions
    % where input is assumed to have size [NumChildren 4]). If 'Parent' or 'Children' it simply ADDS TO THE EXISTING chldren/parent objects (if any).
    %
    % Usage: [ newflags ] = myset(hs, [Name, Value, ...])
    %   hs -- Array of handles. If non-scalar, property is applied to ALL HANDLES IN ARRAY. Thought about allowing cell-array of inputs for
    %       non-scalar hs, but not that useful and would actually go beyond functionality of Matlab's ORIGINAL "set.m"
    %   Name -- Fieldname; if EXISTS (case-insensitive), we overwrite; if DOES NOT EXIST, we create and write
    %   Value -- Assigned to fieldname
    %   newflags -- Boolean vector where 1st dimension is Nth element of flattened hs array, 2nd dimension each element corresponds to each "Name"
    %           If TRUE we declared "NEW" property in UserData structure, if FALSE property already existed
    %           Decided to output this since this is what essentially differentiates "myset" from "set"; "myset" can write NEW/user-defined "properties"
    %
    % NOTE this is generalized to give arbitrary array output for hs, but better to output graphics objeects all in vectors
    assert(all(isobject(hs)) && mod(length(varargin),2)==0 && all(cellfun(@ischar,varargin(1:2:length(varargin)))), ...
        'myset:Bad input. Arg1 must be object handle array, followed by Name-Value pairs.');
    hsz = size(hs); hs = hs(:);
    newflags = zeros(numel(hs),length(varargin)/2)==1;
    for ih=1:length(hs)
        hInfo = get(hs(ih),'UserData');
        if isempty(hInfo); hInfo = struct(); end % even CREATE STRUCTURE FOR FIRST TIME here; neat!
        %% Loop through N-V pairs
        for ii=1:2:length(varargin)-1
            field = varargin{ii};
            switch lower(field)
            case 'position'
            %% Position of object or sub-objects (used when re-shuffling objects); this is considered "overwrite"
                tp = get(hs(ih),'Type');
                switch tp
                case 'hggroup'; ch = get(hs(ih),'Children');
                otherwise; ch = hs(ih);
                end
                % type
                assert(any(strcmpi(get(ch(1),'Type'),{'axes','text','figure'})),'Ojbect/object group does not have "Position" property.');
                assert(size(varargin{ii+1},1)==numel(ch),'Not enough position vectors for specified object/object group.');
                oldunits = get(ch,'Units'); if ~iscell(oldunits); oldunits = {oldunits}; end
                set(ch,'Units','inches');
                for ich=1:numel(ch);
                    set(ch(ich),'Position',varargin{ii+1}(ich,:));
                    set(ch(ich),'Units',oldunits{ii});
                end
            case {'children','parent'}
            %% If writing children/parent objects, just ADD TO OTHERS; do not overwrite
                field = lower(field); field(1) = upper(field); % capitalize
                iflags((ii+1)/2) = false; % we are not overwriting, regardless
                if isfield(hInfo,field)
                    oldhandles = hInfo.(field);
                else
                    newflags(ih,(ii+1)/2) = true;
                    oldhandles = gobjects(0,1); % place
                end
                assert(isobject(varargin{ii+1}),'Object(s) you are trying to save as "Children"/"Parent" is not a(n array of) graphics object handle(s).');
                hInfo.(savename) = [oldhandles; varargin{ii+1}(:)];
            otherwise
            %% UserData properties
                % find fieldname (case insensitive match). IF EXISTS, use origial name case, IF DOES NOT, use new name with PROVIDED CASE. doesn't matter too much though
                fields = fieldnames(hInfo); % result is always cell array, even if singleton
                fieldfind = cellfun(@(x)strcmpi(x,field),fields);
                if any(fieldfind) % NOTE fieldfind could be empty; any([]) is "false"
                    savename = fields{fieldfind}; 
                else
                    newflags(ih,(ii+1)/2) = true; % write for first time
                    savename = field; 
                end
                % record
                hInfo.(savename) = varargin{ii+1};
            end
        end
        %% Write UserData
        set(hs(ih),'UserData',hInfo);
    end
