function [ newlons, newlats, newdata ] = geopadarray( lons, lats, data, varargin )
    % Robust function for padding geographic arrays, allowing seamless spherical grid operations, e.g.
    % splines and finite differencing. Pads over poles/along longitudes.
    %
    % Usage: [newlons, newlats, newarr] = geopadarray( lons, lats, data )
    %        [newlons, newlats, newarr] = geopadarray( lons, lats, data, run )
    %        [newlons, newlats, newarr] = geopadarray( lons, lats, data, run, pad_direction )
    %
    % Default "run" is 1, "pad_direction" is "both" (also pre/post allowed). Pads in X AND Y.
    % Note lats do not necessarily have to be regular, but LONS MUST BE REGULAR.
    %
    % If the array is not exactly circular in longitude, or lat vector boundaries are not on 90N and 90S,
    % we pad edges with NaNs instead and artificially extends lon, lat vectors.
    %
    % Q: When should I use this function? 
    % A: If you're computing derivative w.r.t. latitude, need
    % to extend edges by 1. If you compute spherical laplacian,
    % extend edges by 2 (2 derivatives = 2 finite differences). If 
    % you're computing a spline interpolation (e.g. to another grid), 
    % need to extend by 3 (it's cubic). For linear, by 1. If you're adding contour lengths
    % or otherwise want to show contours that wrap meet *exactly* at the same point, should 
    % pad by 1 'pre' or 'post' (contouring uses linear interpolation, no extrapolation from 
    % grid center convex boundary).
    %
    % Example: 
    % data = rand(9,18); latb = -90:30:90; lat = -75:30:75; lonb = 0:60:360; lon = 30:60:330;
    % [ newlons, newlats, newdata ] = geopadarray( {lon lonb}, {lat latb}, data, 2 );
    % set visual to "1" to get a visualization of the old vs. new data matrix.
    
    %% Parse input
    visual = 0;
    pad_direction = 'both';
    run = 1;
    if ~isempty(varargin)
        if length(varargin)>2
            error('Too many input args.');
        end
        for iargin=1:length(varargin)
            if isscalar(varargin{iargin})
                run = varargin{iargin};
            end
            if ischar(varargin{iargin})
                switch varargin{iargin}
                case 'visual'
                    visual = 1;
                case {'both','pre','post'}
            	    pad_direction = varargin{iargin};
                otherwise
                    error('Unknown switch: %s',varargin{iargin});
                end
            end
        end
    end
    lon_in = lons{1}(:); lat = lats{1}(:); lonb_in = lons{2}(:); latb = lats{2}(:);  
    if any(diff(lon_in))<0 || any(diff(lat))<0
        error('Lons, lats must be monotonically increasing. If array is exactly circular, set lonb(end)==lonb(1)+360.');
    end
    if length(lon_in)~=size(data,1) || length(lat)~=size(data,2)
        error('Size mismatch or wrong permutation. Need lons on 1st dim, lats on 2nd.');
    end
    lon = mod(lon_in,360); lonb = mod(lonb_in,360); % enforce mod(360)

    %% Pad
    datsz = size(data); nlon = length(lon); nlat = length(lat);
    newlen = prod(datsz(3:end)); % returns "1" if empty. good job on this one, Matlab.
    data = reshape(data,[nlon nlat newlen]);
    
    newdata = NaN([nlon+2*run nlat+2*run newlen]);
    for id=1:size(data,3)
        %% Take slice
        tdat = data(:,:,id);
       
        %% Latitudinal padding
        % Latitudes must get padded first
        for latside=1:2 % pad top, then bottom.
            padarr = NaN([length(lon) run]); padlat = NaN([run 1]); padlatb = NaN([run 1]);
            if latside==1;
                fillswtch = (latb(end)==90); fact = 1; box = latb(end)-latb(end-1); latst = lat(end); latbst = latb(end);
                offloop = 0:run-1;
                cstrt = nlat; bstrt = nlat+1; % "start" for lat "centers", data; and for lat "boundaries"
                insloop = [1:run];
            else
                fillswtch = (latb(1)==-90); fact = -1; box = latb(2)-latb(1); latst = lat(1); latbst = latb(1);
                offloop = 0:-1:-run+1;
                cstrt = 1; bstrt = 1;
                insloop = [run:-1:1];
            end
            for r = 1:run
                insid = insloop(r); % "insert" loop
                offid = offloop(r); % "offset" loop
                if fillswtch % we have data up to north pole; run over the edge.
                    for ilon=1:length(lon)
                        overpole_lon = mod(lon(ilon)+180,360);
                        loc = find(lon==overpole_lon);
                        if ~isempty(loc)
                            padarr(ilon,insid) = tdat(loc,cstrt-offid); % "even" number of lons; just take value across.
                        else
                            [~,ucent] = min(mod(lon-lonoff,360));
                            if ~isempty(ucent) % interpolate to new value
                                if ucent==1
                                    lcent = nlon; lowloncent = lon(lcent)-360;
                                else
                                    lcent = ucent-1; lowloncent = lon(lcent);
                                end
                                midlonb = lonb(ucent);
                                uploncent = lon(ucent);
                                padarr(ilon,insid) = (tdat(lcent,cstrt-offid)*(mod(midlonb-lowloncent,360)) + ...
                                                         tdat(ucent,cstrt-offid)*(mod(uploncent-midlonb,360)))/mod(uploncent-lowloncent,360);
                                     % weighted mean. should also allow for spline? maybe
                            end % else... leave as NaN
                        end
                    end % lon loop
                    padlat(insid) = 180*fact-lat(cstrt-offid); 
                        % e.g. for first run at -90N, equals -180-lat(1-0)=-180-lat(1)=-90.5 if, say, lat(1) is -89.5.
                        % second run, equals 2*(-90)-lat(1-(-1))*-1=-180+lat(2)=-91.5 if, say, lat(2) is -88.5
                        % at 90N, equals 180-lat(end-0)=90.5 if, say, lat(end) is 89.5
                    padlatb(insid) = 180*fact-latb(bstrt-offid-fact);
                        % e.g. for first run at -90N, equals -180-latb(1-0-(-1))=-180-latb(2)=-91 if, say, latb(2) is -89.
                        % at 90N, equals 180-latb(end-0-1) = 180-latb(end-1) = 91 if, say, latb(end-1) is 89.
                else
                    padlat(insid) = latst + box*(offid+fact);
                        % e.g. for north bound with max lat of 89.5, gives 89.5+1*1=99.5
                        % for south bound, min lat -89.5, gives -89.5+(-1)*1=-99.5
                    padlatb(insid) = latbst + box*(offid+fact);
                end
            end
            if latside==1
                if id==1
                    newlat = [lat; padlat]; newlatb = [latb; padlatb];
                end
                tdat = [tdat padarr];
            else
                if id==1
                    newlat = [padlat; newlat]; newlatb = [padlatb; newlatb];
                end
                tdat = [padarr tdat];
            end   
        end % testing top lat boundary and bottom lat boundary
        
        %% Longitudinal padding
        if lonb(end)==lonb(1) % they match perfectly; remember, we mod-360'd the lons
            tdat = [tdat(end-run+1:end,:); tdat; tdat(1:run,:)];
            if id==1
                newlon = [lon(end-run+1:end); lon_in; lon(1:run)]; % the "input" preserves the form of our lons (e.g. -180 to 180 vs. 0 to 360). then will enforce montonic.
                newlonb = [lonb(end-run:end-1); lonb_in; lonb(2:run+1)];
            end
        else
            tdat = padarray(tdat,[run 0],NaN,'both');
            if id==1
                lowbox = mod(lonb(2)-lonb(1),360); highbox = mod(lonb(end)-lonb(end-1),360);
                lowpad = NaN([run 1]); highpad = lowpad; lowbpad = lowpad; highbpad = lowpad;
                for offid=1:run
                    lowpad(offid) = mod(lon(1)-lowbox*offid,360); 
                    highpad(offid) = mod(lon(end)+highbox*offid,360);
                    lowbpad(offid) = mod(lonb(1)-lowbox*offid,360);
                    highbpad(offid) = mod(lonb(end)+highbox*offid,360);
                end
                newlon = [lowpad; lon_in; highpad]; % the "input" preserves the form of our lons (e.g. -180 to 180 vs. 0 to 360). then will enforce montonic.
                newlonb = [lowbpad; lonb_in; highbpad];
            end
        end

        %% Re-enforce monotonic lons
        if id==1
            lowlon = find(newlon(1:run)>lon_in(1)); newlon(lowlon) = newlon(lowlon)-360;
            lowlonb = find(newlonb(1:run)>lonb_in(1)); newlonb(lowlonb) = newlonb(lowlonb)-360;
            hilon = find(newlon(end-run+1:end)<lon_in(end)); newlon(nlon+run+hilon) = newlon(nlon+run+hilon)+360; 
            hilonb = find(newlonb(end-run+1:end)<lonb_in(end)); newlonb(nlon+run+1+hilonb) = newlonb(nlon+run+1+hilonb)+360;
        end

        %% Visualize
        if id==1 && visual;
            f=figure; subplot(1,2,1); h=pcolor(lonb_in,latb,padarray(data(:,:,id)',[1 1],NaN,'post')); set(h,'EdgeColor','none'); set(gca,'YDir','normal','CLim',[0 1],'XTick',lonb_in,'YTick',latb); title('Before'); 
            subplot(1,2,2); h=pcolor(newlonb,newlatb,padarray(tdat',[1 1],NaN,'post')); set(h,'EdgeColor','none'); set(gca,'CLim',[0 1],'YDir','normal','XTick',newlonb,'YTick',newlatb); title('After');
            hold on; xl = get(gca,'XLim'); yl = get(gca,'YLim');
            plot([lonb(1) lonb(1)],yl,'r','LineWidth',2); plot([lonb(end) lonb(end)],yl,'r','LineWidth',2); 
            plot(xl,[latb(1) latb(1)],'r','LineWidth',2); plot(xl,[latb(end) latb(end)],'r','LineWidth',2); hold off;
            set(gcf,'Position',[50 50 1600 800]); pause(5); close(f);
        end
        
        %% Save
        newdata(:,:,id) = tdat;
    end

    %% Just wanted along one direction?
    scale = 2;
    switch pad_direction
    case 'both' % we just did that. this script was designed with both-sides padding in mind
        % (useful for spherical-coordinate derivatives and such) so it may be complicated to change. isn't very intensive so we can just
        % pad on both edges then remove the extras (see 2 following cases).
    case 'post'
        newdata = newdata(run+1:end,run+1:end,:);
        newlon = newlon(run+1:end); newlonb = newlonb(run+1:end);
        newlat = newlat(run+1:end); newlatb = newlatb(run+1:end);
        scale = 1;
    case 'pre'
        newdata = newdata(1:end-run,1:end-run,:);
        newlon = newlon(1:end-run); newlonb = newlonb(1:end-run);
        newlat = newlat(1:end-run); newlatb = newlatb(1:end-run);
        scale = 1;
    end
    
    %% Output
    newdata = reshape(newdata, [nlon+scale*run nlat+scale*run datsz(3:end)]);
    newlats = {newlat, newlatb};
    newlons = {newlon, newlonb};
    fprintf('Done padding.\n')
 end
