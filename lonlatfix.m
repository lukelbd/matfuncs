function [ outlon, outlat, outdata ] = lonlatfix( lon, lat, data, varargin );
    % Simple function for fixing geographic file dimensions
    % Usage:    [ outlon, outlat, outdata ] = lonlatfix( lon, lat, data )
    %       and we auto-detect longitude, latitude dimensions based on lon, lat input
    %                                   ... = lonlatfix( lon, lat, data, permute )
    %       where "permute" is string "auto" or length 3-4 vector, indicating location of (1) lon, (2) lat, (3) time 
    %       OR (1) lon, (2) lat, (3) z, (4) time
    %                                   ... = lonlatfix( ..., N-V pairs )
    %       where the options are
    %           <'center', loncenter> for starting longitude value (we mod-360 it)
    %           <'mode', lonmode> where lonmode=0, lonmode=180 for longitudes -180 to 180 numbering OR lonmode=1, lonmode=360 for longitudes 0 to 360 numbering
    %% EDIT needed: allow z dimension, and auto-arrange pressure levels, etc.
    %% ...currently allow a passive z dimension only
    
    % Parse
    assert(ndims(data)<=4 && isvector(lon) && isvector(lat), 'Bad input.');
    loncent = 0; lonmode = 0; perm = 'auto'; % lonmode 0 is -180 to 180; lonmode 1 is 0 to 360
    if ~isempty(varargin); nargs = length(varargin);
        % permute argument
        if strcmpi(varargin{1},'auto') || (isnumeric(varargin{1}) && any(numel(varargin{1})==[3 4]));
            perm = varargin{1}; varargin = varargin(2:end); nargs = nargs-1; 
        end
        % N-V pairs
        assert(mod(length(varargin),2)==0,'Bad N-V pairs.');
        for ii=1:2:nargs-1 % if nargs=0, loop is skipped
            assert(ischar(varargin{ii}) && ii+1<=nargs,'Bad N-V pair.');
            switch lower(varargin{ii})
            case {'loncent','cent','loncenter','center'}
                loncent = varargin{ii+1};
            case {'lonmode','xmode','mode'}
                switch varargin{ii};
                case {0,180}
                    lonmode = 0;
                case {1,360}
                    lonmode = 1;
                otherwise; error('Bad N-V pair.');
                end
            end
        end
    end

    % Permutations
    lon = lon(:); lat = lat(:);
    if strcmpi(perm,'auto');
        sz = size(data); x = find(sz==length(lon)); y = find(sz==length(lat));
        assert(numel(x)>0 && numel(y)>0, 'Data dimension mismatch.');
        assert(numel(x)==1 && numel(y)==1 && length(lon)~=length(lat), 'Ambiguous dimensions.');
        perm = 1:4; perm(perm==x) = []; perm(perm==y) = []; perm = [x y perm];
    else
        assert(length(lon)==size(data,1) && length(lat)==size(data,2), 'Data dimension mismatch.');
    end
    data = permute(data, perm); % places onto EITHER [x, y, t] OR [x, y, z, t]

    % Flipping
    lontest = lon(2)-lon(1); lattest = lat(2)-lat(1);
    if lontest<0; lon = flipud(lon(:)); data = data(end:-1:1,:,:); end; %flipud(data); end;
    if lattest<0; lat = flipud(lat(:)); data = data(:,end:-1:1,:); end; %fliplr(data); end;

    % Circular shifts (allow loncent to be flexible, because sometimes might even want cutoff 
    % over Europe/Africa if focusing on oceans, e.g., or some other weird longitude)
    lon = mod(lon,360); % 0 to 359
    baselon = mod(loncent-180,360);
    londiff = lon-baselon; id = find(lon-baselon>=0,1,'first'); % then circshift left by id-1
    data = circshift(data,[id-1 0 0 0]); lon = circshift(lon,id-1);

    % Longitude indexing
    if lonmode==0; lon(lon>180) = lon(lon>180)-360; end

    % Output
    outlon = lon; outlat = lat; outdata = data;

