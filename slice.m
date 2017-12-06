function [ data ] = slice( D, Dfilt, data )
    % Matlab REALLY should already have something like this... just takes slice from
    % variable dimension index. Order of inputs is supposed to be reminiscent of 'cat'
    %
    % Usage: data = slice( d, Dfilt, data )
    %       -'d' is the dimension id for data along which we slice
    %       -'Dfilt' is the filter, a logical vector equal to the length of dimension d
    %           or list of numbers
    %       -'data' is the data
    %
    % Right now can't take slice from more than one unknown dimension at once; user should
    % just use this function multiple times to get slices.

    %% Check
    if nargin==2; 
        data = Dfilt;
        Dfilt = D;
        assert(isvector(Dfilt) && numel(Dfilt)==ndims(data), ...
            ['Slice ids must be cell vector, or vector of scalars ' ...
            'matching data dimensionality.']);
        D = 1:numel(Dfilt); % these are the "dimensions"
    elseif nargin==3
        assert(isscalar(D) && D>=1 && D<=ndims(data),['Dimension id must be ' ...
            'scalar, within dimensionality of input data.']);
        assert(isvector(Dfilt),'Slice ids must be a vector.');
    else, error('Bad number of input args.');
    end
    %% Loop through slicing dimensions
    for ii=1:length(D)
        d = D(ii);
        if nargin==2 
            if iscell(Dfilt), dfilt = Dfilt{ii};
            else, dfilt = Dfilt(ii);
            end
        else
            dfilt = Dfilt;
        end
        %% Prelim
        dsz = size(data);
        if (islogical(Dfilt) && numel(Dfilt)==dsz(d))
            n = sum(double(Dfilt)); % needed for reshaping later
        elseif (all(Dfilt)>=1 && all(Dfilt)<=dsz(d))
            n = numel(Dfilt);
        else
            error('Bad slice id argument; exceeds dimension size.');
        end
        %% Run
        dlist = 1:numel(dsz); dlist(d) = []; dsz(d) = [];
        permuteid = [d dlist]; shapeid = [n dsz]; % place time on first dimension
        % apply
        data = permute(data,permuteid);
        data = reshape(data(Dfilt,:),shapeid);
        data = ipermute(data,permuteid); % inverse permute, to original
    end
