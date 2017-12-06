function [distances, outlon, outlat] = geodist(lon1, lat1, lon2, lat2)
    % Gets great circle distance between two coordinates.
    % Usage: dist = geodist(lon1, lat1, lon2, lat2), where...
    %       [dist, reflon, reflat] = geodist(...)
    %   -dist is km 
    %   -all coordinates in degrees, and in 2-D matrices
    %   -reflon, reflat gives...
    %       --for only lon1, lat1 input (want respective distances), the ids 
    %           along each side of right-triangular matrix
    %       --for either lon1,lat1 or lon2,lat2 scalar (but not neither), the 
    %           ids of the non-scalar longitude and latitude array
    %
    % IMPORTANT DETAILS:
    % For lon1, lat1, accepts...
    %   -ARRAY/SCALAR input, provided each are same shape
    %   -VECTORS of different sizes for unfurling distances from EVERY POINT W.R.T.
    %       ONE ANOTHER in a grid (make sure one is row, the other column, for safety)
    % ...and for lon2, lat2, accepts...
    %   -SCALAR/ARRAY input to pair with lon1, lat1 ARRAY/SCALAR input (respectively)
    %   -ARRAY input same size as lon1, lat1 ARRAY inpu
    %   -NO INPUT, if we want distances w.r.t. respective points in lon1, lat1 input
    %

    %% Constants
    RADIUS = 6371.0; % mean Earth radius

    %% lon1, lat1 processing
    % dimensions?
    assert(ndims(lon1)==2 && ndims(lat1)==2,'lon1, lat1 must be 2-D.');
    % is input a grid?
    if ~all(size(lon1)==size(lat1)) % different length vectors, or column and row
        assert(isvector(lon1) && isvector(lat1), ...
            'to build grid, lon1 and lat1 must be vectors.');
        [lon1, lat1] = ndgrid(lon1(:),lat1(:)); % lons along dim1, lats dim2
    end
    %% lon2, lat2 processing
    % exists?
    if exist('lon2')~=1 && exist('lat2')~=1, Triflag = true;
        % will make (location) by (location) matrix of distances, right triangular
    else, Triflag = false;
    end
    if ~Triflag
        % dimensions?
        assert(ndims(lon2)==2 && ndims(lat2)==2,'lon2, lat2 must be 2-D.');
        % is input a grid?
        if ~all(size(lon2)==size(lat2)) % different length vectors, or column and row
            assert(isvector(lon2) && isvector(lat2), ...
                'to build grid, lon2 and lat2 must be vectors.');
            [lon2, lat2] = ndgrid(lon2(:),lat2(:));
        end
        %% check against lon1, lat1
        if ~all(size(lon1)==size(lon2)) % note lon1, lat1 and lon2, lat2 match by now
            assert(isscalar(lon1) || isscalar(lon2), ...
                ['If lon1, lat1 and lon2, lat2 coordinates do not match in size, ' ...
                'one of them must be SCALAR.']);
        end
    end

    %% Haversine Formula, and conversion to units "km"
    deltasigma = @(lon1,lon2,lat1,lat2)RADIUS*abs(2*asin(sqrt( ...
        sin(((lat2-lat1)/2)*pi/180).^2 + ...
        cos(lat1*pi/180).*cos(lat2*pi/180).*sin(((lon2-lon1)/2)*pi/180).^2 ...
            ))); % great-circle distance on spherical coordinates
        % note this is compatible with any combination of scalar or array-shape
        % lon1, lon2, lat1, and lat2; any non-scalar args must be same size

    %% Compute
    if Triflag;
        % flatten
        N = prod(size(lon1));
        lon1 = reshape(lon1,[N 1]); % explicitly reshape; easier to understand
        lat1 = reshape(lat1,[N 1]);
        distances = NaN(N,N); % square array
        yid = @(kk)(ceil(kk/ny)); % rounds UP to nearest multiple of ny, 
        xid = @(kk)(mod(kk,nx-1)+1); % ...this is why python starts at zero index; makes things like circular retrieval
            % and mod MUCH more natural
        for ii=1:N
            vec = ii+1:N;
            distances(ii,vec) = deltasigma(lon1(ii),lat1(ii),lon2(vec),lat2(vec));
                % operation vectorized as much as possible
        end
        outlon = lon1; outlat = lat1;
    else
        distances = deltasigma(lon1,lon2,lat1,lat2);
        if isscalar(lon2) && ~isscalar(lon1)
            outlon = lon1; outlat = lat1;
        elseif isscalar(lon1) && ~isscalar(lon2)
            outlon = lon2; outlat = lat2;
        else
            outlon = NaN; outlat = NaN;
        end
    end
end
