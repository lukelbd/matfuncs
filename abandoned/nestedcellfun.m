function [ ndata, ndimids ] = nestedcellfun( action, data, varargin )
    % Use this function when we have several data arrays in network of nested cells, with same 
    % dimensionality but not necessarily same dimension indices, and we want to perform a single 
    % action on all of them at once.
    %
    % Input - "data" can be just an array, a cell-array of arrays, or a cell-array of cell-array of arrays
    % Call with get_operation( action, data, varargin ). "action" can be:
    %   "permute";      usage: ndata = get_operation('permute', data, permutearray)
    %   "getfield";     usage: ndata = get_operation('getfield', data, fieldstring)
    %   "function";     usage: ndata = get_operation('function', data, fhandle)
    %   "scale";        usage: ndata = get_operation('scale', data, dim) which scales vectors along 
    %                       dimension "dim" such that their minima are 0 and maxima are 1.
    %   "simplemean";   usage: [ndata, ndimids] = get_operation('simplemean', data, dim, dimids, idlimits) mean along given dimension
    %                       s.t. dimids>=idlimits(1) & dimids<=idlimits(2). ndimids == idlimits.
    %   "slice";        usage: [ndata, ndimids] = get_operation('slice', data, dim, dimids, idpick) get array "slice" where dimids==idpick
    %                       for dimension "dim". ndimids == idpick.
    %   "filter";       usage: [ndata, ndimids] = get_operation('filter', data, dim, dimbordids, idlimits) filter such that data boxes
    %                       are entirely within [idlimits(1), idlimits(2)]. must input border dimension ids, not centers. ndimids == [min, max]
    %                       of "dimbordids" that satisfy this.
    %   "mean";         usage: [ndata, ndimids] = get_operation('mean', data, dim, dimbordids, idlimtis) take box-width-weighted mean,
    %                       correcting for boxes that are only partially within requested range of "idlimits." ndimids == idlimits.
    %   "interp";       usage: [ndata, ndimids] = get_operation('interp', data, dim, dimbordids, idquery) LINEAR interpolation to query
    %                       points. ndimids == idquery.

    % Can have e.g. data= {{W1,W2},{W1,W2,W3}} but dimids= {D1,D2}, dimids equivalent for each W1 within

    %% Parse inputs
    if length(varargin)==1
        dim = 0;
        dimids = 0; % don't need dim
        actionid = varargin{1};
    elseif length(varargin)==2
        switch action
        case {'simplemean', 'mean'} % implicitly assumes user wants mean of whole area
            dim = varargin{1};
            dimids = varargin{2};
            actionid = [dimids(1) dimids(end)]; 
        otherwise
            error('Incorrect number of input arguments.');
        end
    elseif length(varargin)==3 || length(varargin)==4;
        dim = varargin{1};
        dimids = varargin{2};
        actionid = varargin{3};
    else
        error('Incorrect number of input arguments.');
    end

    %% Main
    if iscell(data)
        dloop1 = 1:length(data); 
        trig1 = true; 
        ndata = cell(size(data));
    else
        dloop1 = 1; 
        trig1 = false;
    end
    for d1 = dloop1;
        if trig1
            data1 = data{d1};
        else
            data1 = data;
        end
        if iscell(dimids)
            dimids1 = dimids{d1};
            dtrig1 = true;
        else
            dimids1 = dimids;
            dtrig1 = false;
        end
        if iscell(data1); 
            dloop2 = 1:length(data1); 
            trig2 = true;
            ndata1 = cell(size(data{d1}));
        else
            dloop2 = 1;
            trig2 = false;
        end
        for d2 = dloop2;
            if trig2
                data2 = data1{d2};
            else
                data2 = data1;
            end
            if iscell(dimids1)
                dimids2 = dimids1{d2}
                dtrig2 = true;
            else
                dimids2 = dimids1;
                dtrig2 = false;
            end
            isvector = @(x)(ndims(size(squeeze(x)))==2 && sum(size(squeeze(x))==1)==1 && ~isempty(x));
            fprintf('Triggers: var %d, %d; dim %d, %d\n',trig1, trig2, dtrig1, dtrig2);

            %% Simple actions
            if strcmp(action,'permute')
                if ~isvector(actionid)
                    error('Permute array must be vector.');
                end
                data2 = permute(data2, actionid);
            elseif strcmp(action,'getfield')
                if ~ischar(actionid)
                    error('Field name must be character array.');
                end
                data2 = [data2.(actionid)]; % if structure is multidimensional, puts items into array
            elseif strcmp(action,'function')
                if ~isa(actionid,'function_handle')
                    error('Must input function handle.');
                end
                data2 = actionid(data2);
            elseif strcmp(action,'scale') % set max to 1, min to zero along specified dimension
                if ~isscalar(actionid)
                    error('Dimension index must be scalar.')
                end
                repmatarr = ones(1,ndims(data2));
                repmatarr(actionid) = size(data2, actionid);
                data2 = (data2-repmat(min(data2, [], actionid), repmatarr))./(repmat(max(data2, [], actionid), repmatarr)-repmat(min(data2, [], actionid), repmatarr));
                        % dimids unchanged
            else
                if ~isvector(dimids2)
                    error('Dimension IDs must be vector.');
                end
                
                %% Flip if necessary
                arr = 1:ndims(data2); arr(dim) = [];
                data2 = permute(data2, [dim arr]);
                newsize = size(data2);
                if dimids(2)-dimids(1)<0
                    fliparr = true;
                    dimids2 = flip(dimids2);
                    data2 = flipud(data2);
                else
                    fliparr = false;
                end
                %% Actions
                switch action
                case 'simplemean'
                    if length(dimids2)~=size(data2,1)
                        error('Dimension IDs do not match data2 size for requested dimension.');
                    end
                    filt = find([dimids2>=actionid(1) & dimids2<=actionid(end)]);
                    data2 = mean(data2(filt,:),1); % use if dimension Ids evenly spaced, and data box edges fall on both boundaries of the mean range we want.
                        % for time, e.g. can assume a snapshot represents the state for the following
                        % 6 hours, so that a time mean from 0UTC Jan 1 to 18UTC Jan 31 represents the 
                        % continuous period 0UTC Jan 1 to 0UTC Feb 1
                    dimids2 = actionid; % new time range
                    data2 = reshape(data2, [size(data2,1) newsize(2:end)]);
                case 'normalize' % percent deviations w.r.t. TOTAL mean
                    if length(dimids2)~=(size(data2,1)+1)
                        error('Must input dimension ID *borders*, not centers.')
                    end
                    dx = dimids2(2:end)-dimids2(1:end-1);
                    dx = dx(:);
                    data2 = data2./repmat(sum(data2.*repmat(dx,[1 newsize(2:end)]),1),[newsize(1) 1]);
                        % dimids unchanged
                case 'slice'
                    if ~isscalar(actionid)
                        error('Must specify scalar for ID of "slice."');
                    end
                    data2 = data2(actionid,:);
                    data2 = reshape(data2, [1 newsize(2:end)]);
                    dimids2 = actionid;
                case {'mean','filter','interp'}
                %% Allows for uneven spacing of grid points, and range that falls between grid 
                % note: weighted box-counting with discreteness taken into account should give
                    if actionid(2)-actionid(1)<=0
                        error('Mean range must be of form [lowvalue, highvalue], highvalue>lowvalue (mean, filter) or monotonically increasing (interpolation).');
                    end
                    if actionid(1)<dimids2(1) || actionid(end)>dimids(end)
                        error('Requested region outside of interpolation range.')
                    end
                    filt = find([dimids2>=actionid(1) & dimids2<=actionid(end)]);
                    if strcmp(action,'mean')
                        if length(dimids2)~=(size(data2,1)+1)
                            error('Must input dimension ID *borders*, not centers.');
                        end
                        if numel(actionid)~=2
                            error('Need two-value mean range.');
                        end
                        filt = filt(1:end-1); % index of valid WHOLE grid centers
                        dx = dimids2(2:end)-dimids2(1:end-1); % requires dimids2 to be border array
                        dx = dx(:); dx = dx(filt);
                        dx
                        size(dimids2)
                        size(dx)
                        y = data2(filt,:);
                        if isempty(dimids2==actionid(1)); 
                            dx = [dimids2(filt(1))-actionid(1); dx];
                            y = [data2(filt(1)-1,:); y];
                        end
                        if isempty(dimids2==actionid(2));
                            dx = [dx; actionid(2)-dimids2(filt(end)+1)]; 
                            y = [y; data2(filt(end)+1,:)];
                        end
                        data2 = sum(y.*repmat(dx,[1 size(y,2)]),1)/sum(dx);
                        dimids2 = actionid; % actual mean range
                        data2 = reshape(data2, [size(data2,1) newsize(2:end)]);
                    elseif strcmp(action,'filter')
                        if numel(actionid)~=2
                            error('Need two-value filter range.');
                        end
                        if length(dimids2)~=(size(data2,1)+1)
                            error('Must input dimension ID *borders*, not centers.');
                        end
                        filt = filt(1:end-1);
                        data2 = data2(filt,:);
                        dimids2 = dimids2([filt(1) filt(end)]); % actual grid boundary range
                        data2 = reshape(data2, [size(data2,1) newsize(2:end)]);
                    elseif strcmp(action,'interp')
                        if ~isvector(actionid)
                            error('Interpolant IDs must be vector.');
                        end
                        data2 = interp1(dimids2, data2, actionid, 'linear'); % just interpolate the grid centers
                        dimids2 = actionid; % new grid centers
                    end
                otherwise 
                    error('Invalid action.');
                end
                if fliparr
                    dimids2 = flip(dimids2);
                    data2 = flipud(data2);
                end
                data2 = ipermute(data2, [dim arr]);
            end % possible actions
            if trig2
                ndata1{d2} = data2;
            else
                ndata1 = data2;
            end
            if dtrig2
                ndimids1{d2} = data2;
            else
                ndimids1 = data2;
            end
        end % innerloop
        if trig1
            ndata{d1} = ndata1;
        else
            ndata = ndata1;
        end
        if dtrig1
            ndimids{d1} = ndimids1;
        else
            ndimids = ndimids1;
        end
    end % outerloop
end
