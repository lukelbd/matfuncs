function metadata_struct = metadata(ncfile, atts)
    %
    % Usage: metadata_struct = loadmetadata(ncfile, atts)
    %
    % Load dimension data and variable attibutes in "atts" cell array of strings for each present 
    % variable (that isn't a data dimension).
    %

    % Quick anonymous functions for dealing with arbitrary netcdf structures in Matlab environment
    cell_streq = @(cells,string)cellfun(@(x)strcmp(x,string),cells); % which cells match some string?
    cell_valeq = @(cells,val,fn)cellfun(@(x)isequal(fn(x),val),cells); % which cells satisfy some numerical operations?

    % Load variable info, parse input
    if nargin==1
        atts = {};
    end
    if ischar(atts)
        attsCHAR = atts; atts = {};
        for ii=1:size(attsCHAR,1); atts = cat(1,atts,{attsCHAR(ii,:)}); end
    end
    allinfo = ncinfo(ncfile); vinfo = allinfo.Variables;
    
    % Criteria for classifying item as variable, not dimension
    wantids = logical(ones(length(vinfo),1));
    for ivar = 1:length(vinfo)
        ids = cell_streq({allinfo.Dimensions.Name}, vinfo(ivar).Name);
        if any(ids); wantids(ivar) = false; end % test the name
        vsize = vinfo(ivar).Size; vtst = vsize<=2;
        if any(vtst) && length(vsize)<=2; wantids(ivar) = false; end % test the shape - ncepdoe reanalysis has weird dimensions, time boundaries are 
            % 2 by ntimes with no corr. dimension name. this flags that field
    end
    varids = find(wantids); dimids = find(~wantids);

    % Create structure array
    metadata_struct = struct();
    for vid = 1:length(varids)
        % Attributes
        varname = vinfo(varids(vid)).Name;
        vstruct = struct(); % create structure with one field (variable name) for each thing. should change id here to the standard index later (i.e. just run nmconvert(##ncinfo name##) on it)
        for atid = 1:length(atts)
            file_atid = find(cell_streq({vinfo(varids(vid)).Attributes.Name},atts(atid))); % get location of file
            if isempty(file_atid)
                if strcmp(atts{atid},'add_offset')
                    vstruct.(atts{atid}) = 0;
                elseif strcmp(atts{atid},'scale_factor')
                    vstruct.(atts{atid}) = 1;
                else
                    fprintf('All attributes:\n'); disp({vinfo(varids(vid)).Attributes.Name});
                    error(sprintf('Requested attribute %s is missing from %s.\n',varname,atts(atid)));
                end
            else
                vstruct.(atts{atid}) = vinfo(varids(vid)).Attributes(file_atid).Value; % put attribute value in variable substructure
            end
        end

        % Sizes
        vstruct.size = vinfo(varids(vid)).Size;
        vstruct.dimensions = {vinfo(varids(vid)).Dimensions.Name}; % the parameter each dim corresponds to

        % Dimension data
        for id = vstruct.dimensions % iterate through cells
            vstruct.(id{:}) = ncread(ncfile, id{:});
        end

        % Finish
        metadata_struct.(varname) = vstruct;
    end

end % function
