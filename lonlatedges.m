[ lonb, latb ] = lonlatedges( lon, lat )
    % Returns edges for longitude, latitude grid center vectors.
    % Longitudes must be regularly spaced, but latitudes can be 
    % irregularly spaced.

    %% Check
    assert(isvector(lon) && isvector(lat),'Input lon, lats must be vectors.');
    assert(diff(lats
    %% Get lons
    % prelim
    lon = lon(:);
    [~,id] = min(lon);
    lon = circshift(lon,-id,1);
    % check
    assert(all(diff(lon))>0,'Lons must be ascending (mod 360) along vector index.');
    assert(all(diff(lon)==londiff),'Lon spacing must be regular.');
    % get
    londiff = mod(lon(2)-lon(1),360); % could be e.g. 0-355
    lonb = [lon(1)-londiff/2:londiff:lon(end)+londiff/2];
    assert(mod(lonb(1),360)==mod(lonb(end),360),'Longitude grid must encircle globe.');
    %% Get lats
    % check
    assert(all(diff(lat))>0,'Lats must be ascending along vector index.');
    % get
    lat = lat(:);
    latb = [-90; (lat(1:end-1)+lat(2:end))/2; 90];

