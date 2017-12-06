function [phands, F, V, xs, ys, cdata] = mycontour2patch(axm,input_d1,input_d2,data,clev,varargin)
    % Reconstructs patch objects associated with contourfm with valid XData, YData, ZData, and Vertices fields (these fields are 
    % *unavailable* in post-2014b Matlab). Suitable for normal x-y data fields, and for map fields using contourm. Ensures contours are
    % CLOSED/CIRCULAR within current 'XLim','YLim' or 'MapLatLimit','MapLonLimit' before conversion to patch objects.
    %
    % Data coverage can be greater than current axis limits, or smaller. By default, if data coverage is greater, 
    % linearly interpolates data to axis limits exactly when the gridpoints don't happen to fall there. If data coverage 
    % is smaller, but graticule/cell edges run up to axis limits, USE "pad" OPTION.
    %
    % IMPORTANT: Current axes XLim/YLim or axesm MapLatLimit/MapLonLimit
    % MUST be set as user intends before applying mycontour2patch. 
    %
    % Usage:    contour2patch(axh, x, y, data, level)
    %           contour2patch(axh, lat, lon, data, level, mapflag)
    %           contour2patch(..., "pad", padtype)
    %           contour2patch(..., Name, Value)
    %           ph = contour2patch(...); [ph, cdata] = contour2patch(...)
    %
    %   contour2patch(axh, x, y, data, level): 
    %       axh is axis handle.
    %       data is in meshgrid format (columns correspond to x/lon, rows to y/lat).  
    %       x, y are data column, row indices.
    %
    %   contour2patch(axh, lat, lon, data, level, mapflag):
    %       lat, lon are latitude/longitude vectors. uses geo-indexed data 
    %       with current axesm projection.
    %           mapflag options: "map" or "mapcirc". 
    %           use "mapcirc" when graticule/cells encompass all longitudes.
    %
    %   contour2patch(..., "pad", padtype):
    %       use if gridpoint/cell centers are all within axis limits, but 
    %       graticule/cell edges run up to axis limits. will add new "centers" on
    %       axis limis that match the closest gridpoint. 
    %   
    %       padtype can be "all" or any subset/permutation of "udlr" for padding on
    %       top/bottom/left/right of data array.
    %
    %       Example: if gridpoint center x coordinates are from .5 to 9.5, cell width 1, 
    %       and axis limits [0, 10], contour2patch(..., "pad", "lr") will 
    %       augment x-indexing/data such that x = [xlim(1); x; xlim(2)], 
    %       data = [data(:,1), data, data(:,end)].
    %   
    %   contour2patch(..., Name, Value):
    %       add Name, Value pairs to change patch properties. note "EdgeColor" 
    %       property is "none" by default.
    %
    %       Example: contour2patch(...,"FaceAlpha", .5, "FaceColor", 'r').
    %
    %   ph = contour2patch(...); [ph, F, V, xs, ys, cdata] = contour2patch(...):
    %       return patch object handle vector ph, faces, vertices, cell-vector of x-
    %       coordinates, cell-vector of y-coordinates, and/or Contour Matrix cdata
    %       (which contains vertices for current patch object)
    %
    %   works for any coordinate system with constant-coordinate boundaries
    %   (e.g. polar conic map projections, cylindrical/pseudo-cylindrical
    %   map projections, and ordinary x-y coordinates, but not e.g. non-polar conic 
    %   map projections or others with variable boundaries. 

    %% Defaults
    getfunc = @get; setfunc = @set;
    patchargs = struct();
    x_limkey = 'XLim'; y_limkey = 'YLim';
    id1 = 1; id2 = 2;
    verbose = false;
    mapflag = false;
    circflag = false;
    npoleflag = false; spoleflag = false;
    lpad = false; upad = false; rpad = false; dpad = false;
    
    %% Parse input, settings
    axes(axm);
    if length(varargin)>=1
        % Switches
        iarg = 1;
        while iarg<=length(varargin)
            switch lower(varargin{iarg})
            case {'map','mapcirc'}
                getfunc = @getm; setfunc = @setm;
                mapflag = true;
                y_limkey = 'MapLatLimit'; x_limkey = 'MapLonLimit';
                id1 = 2; id2 = 1; % latitude on second line of array, longitude on first
                if strcmp(varargin{iarg},'mapcirc'); 
                    circflag = true; % special treatment if grid covers all longitudes
                end
                varargin(iarg) = [];
            case {'npole','nspole','snpole','spole'}
                if ~isempty(strfind(varargin{iarg},'n'))
                    npoleflag = true;
                end
                if ~isempty(strfind(varargin{iarg},'s'))
                    spoleflag = true;
                end
            case 'pad'
                switch varargin{iarg+1}
                case 'all'
                    lpad = true; rpad = true; dpad = true; upad = true;
                otherwise
                    flag = true;
                    if ~isempty(strfind(varargin{iarg+1}),'l')
                        lpad = true; flag = false;
                    end
                    if ~isempty(strfind(varargin{iarg+1}),'r')
                        rpad = true; flag = false;
                    end
                    if ~isempty(strfind(varargin{iarg+1}),'u')
                        upad = true; flag = false;
                    end
                    if ~isempty(strfind(varargin{iarg+1}),'d')
                        dpad = true; flag = false;
                    end
                    if flag;
                        error('Bad pad signifier. Options: "all" or some subset/permutation of "udlr" (up/down/left/right side).');
                    end
                end
                varargin(iarg:iarg+1) = [];
            case 'verbose'
                verbose = true;
                varargin(iarg) = [];
            otherwise
                iarg = iarg+1;
            end
        end
        % Name-value pairs to pass to patch
        if mod(length(varargin(1:end)),2)~=0
            error('Wrong name-value pairs.')
        else
            for iarg=1:2:length(varargin)
                patchargs.(varargin{iarg}) = varargin{iarg+1};
            end
        end
    end
    % Do dimensions match?
    flag = false;
    if mapflag && (size(data,1)~=length(input_d1) || size(data,2)~=length(input_d2)); flag = true; end  % do lats (1st dim) match lats, lon lons?
    if ~mapflag && (size(data,2)~=length(input_d1) || size(data,1)~=length(input_d2)); flag = true; end
    if flag; length(input_d1), length(input_d2), size(data), error('X and Y do not match data size!'); end
    
    %% Filter drawing area based on axis x/y limits
    % Get limits
    if ~isscalar(clev);
        error('Contour level must be scalar.');
    end
    bindata = double(data>=clev);
    y_lim = getfunc(axm, y_limkey); 
    x_lim = getfunc(axm, x_limkey);
    % Map processing
    if mapflag;     
        y = input_d1(:); x = input_d2(:);
        x = mod(x,360);
        x_lim = mod(x_lim,360);
        if circflag;
            xdiff = x-x_lim(1); xdiff(xdiff<0) = NaN;
            [~,circid] = min(xdiff); circid = circid-1;
            bindata = circshift(bindata,[0 -circid]); % sorted west to east, from west border
            x = circshift(x,-circid);
        end
        if npoleflag;
            y = [y; 90]; bindata = [bindata; bindata(end,:)];
        end
        if spoleflag;
            y = [-90; y]; bindata = [bindata(1,:); bindata];
        end  
    else
        x = input_d1(:); y = input_d2(:);
    end
    % Enforce monotonic longitudes
    if mapflag;
        x = lonmonotonic(x); 
        x_lim = lonmonotonic(x_lim);
        while all(x_lim<min(x)) || all(x_lim>max(x))
            if all(x_lim<min(x))
                x = x-360; % sometimes e.g. can get xlim from 0 to 0 mod 360, subtract and get -360 to 0,
                    % while data is from 5 to 355 and goes unchanged. this fixes that circumstance.
            elseif all(x_lim>max(x))
                x = x+360;
            end
        end
    end
    % Get filter
    y_goodr = find(y>=y_lim(1) & y<=y_lim(2));
    if x_lim(1)>=x_lim(2) % e.g. map with west bound 350, east bound 5
        x_goodr = find(x>=x_lim(1) | x<=x_lim(2)); 
    else
        x_goodr = find(x>=x_lim(1) & x<=x_lim(2));
    end
    if verbose; numel(x_goodr), numel(y_goodr), x, x_lim, end
    
    %% Interpolate to get data at plot-region axis limits, and apply frame of zeroes
    % Interpolate to get data values on plot-region axis limits, or 
    % apply padding at limits themselves
    if y(y_goodr(end))<y_lim(2) % otherwise, they are perfectly equal; don't do anything.
        if y_goodr(end)<length(y)
            yid = y_goodr(end);
            edge = interp2(x, y([yid yid+1]), bindata([yid yid+1],:), x, y_lim(2));
            y = [y(1:yid); y_lim(2); y(yid+1:end)]; y_goodr = [y_goodr; y_goodr(end)+1];
            bindata = [bindata(1:yid,:); edge; bindata(yid+1:end,:)];
        elseif rpad % plot-region boundary is *farther* than data edge
            y = [y; y_lim(2)]; y_goodr = [y_goodr; y_goodr(end)+1];
            bindata = [bindata; bindata(end,:)];
        end
    end
    if y(y_goodr(1))>y_lim(1)
        if y_goodr(1)>1
            yid = y_goodr(1);
            edge = interp2(x, y([yid-1 yid]), bindata([yid-1 yid],:), x, y_lim(1)); % interpolate to map limit boundary
            y = [y(1:yid-1); y_lim(1); y(yid:end)]; y_goodr = [y_goodr(1); y_goodr+1];
            bindata = [bindata(1:yid-1,:); edge; bindata(yid:end,:)];
        elseif lpad
            y = [y_lim(1); y]; y_goodr = [y_goodr(1); y_goodr+1];
            bindata = [bindata(1,:); bindata];
        end
    end
    if x(x_goodr(end))<x_lim(2)
        if (x_goodr(end)<length(x) || circflag)
            xid = x_goodr(end); xlen = length(x);
            xsandwich = mod([xid xid+1]-1,xlen)+1; % mod should only affect "circular" data
            if xsandwich(2)~=(xid+1) % enforce monotonic interpolant
                xinterp = [x(xsandwich(1)) x(xsandwich(2))+360];
            else
                xinterp = x(xsandwich);
            end
            edge = interp2(xinterp, y, bindata(:,xsandwich), x_lim(2), y);
            x = [x(1:xid); x_lim(2); x(xid+1:end)]; x_goodr = [x_goodr; x_goodr(end)+1];   
            bindata = [bindata(:,1:xid), edge, bindata(:,xid+1:end)];
        elseif upad
            x = [x; x_lim(2)]; x_goodr = [x_goodr; x_goodr(end)+1]; 
            bindata = [bindata, bindata(:,end)];
        end
    end
    if x(x_goodr(1))>x_lim(1)
        if (x_goodr(1)>1 || circflag)
            xid = x_goodr(1); xlen = length(x);
            xsandwich = mod([xid-1 xid]-1,xlen)+1; % the -1 and +1 make e.g. a length 10 array of x's have ids from 0 to 9, then mod 10 that, then back to ids from 1 to 10
            if xsandwich(1)~=(xid-1) % enforce monotonic interpolant
                xinterp = [x(xsandwich(1))-360 x(xsandwich(2))];
            else
                xinterp = x(xsandwich);
            end
            edge = interp2(xinterp, y, bindata(:,xsandwich), x_lim(1), y);
            x = [x(1:xid-1); x_lim(1); x(xid:end)]; x_goodr = [x_goodr(1); x_goodr+1];
            bindata = [bindata(1,1:xid-1), edge, bindata(:,xid:end)];
        elseif dpad
            x = [x_lim(1); x]; x_goodr = [x_goodr(1); x_goodr+1]; 
            bindata = [bindata(:,1), bindata];
        end
    end
    if verbose; x, y, end
    % Now apply filter
    x = x(x_goodr); y = y(y_goodr);
    bindata = bindata(y_goodr,x_goodr);
    if verbose; x, y, size(bindata), end
    % Add ring of zeros (so contours close around plot-region edge)
    offset = 1e-10;
    bindata = padarray(bindata, [1 1], 0, 'both');
    x = [x(1)+offset; x(1)+offset*2; x(2:end-1); x(end)-offset*2; x(end)-offset];
    y = [y(1)+offset; y(1)+offset*2; y(2:end-1); y(end)-offset*2; y(end)-offset];
    
    %% Finally, apply contour
    if mapflag;
        [cdata, cont] = contourm(y, x, bindata, [.5 .5]);
        if verbose; drawnow; pause(2); end
        delete(cont);
    else
        cdata = contourc(x, y, bindata, [.5 .5]);
    end
    
    %% Pull individual contour vertices in x, y coordinates from contour matrix C
    cid = 1; pid = 1;
    while cid<=size(cdata,2)
        if cdata(1,cid)~=.5; error('Contour doesnt start with contour value... weird.'); end
        nrun = cdata(2,cid);
        id1_vert = cdata(id1,cid+1:cid+nrun); %id1==2, latitude; ==1, "x"
        id2_vert = cdata(id2,cid+1:cid+nrun); %id2==1, longitude; ==1, "y"
        if mapflag;
            [x, y] = mfwdtran(id1_vert, id2_vert); % convert (lat,lon) to (x,y)
        else
            x = id1_vert; y = id2_vert;
        end
        %[x, y] = poly2cw(x, y); % set clockwise orientation by default; they are randomly oriented otherwise
            % Edit: Should work without setting orientation. contours should already be oriented appropriately.
        xs{pid} = x; ys{pid} = y;
        cid = cid+nrun+1;
        pid = pid+1;
    end
    npids = pid-1; % num polynomials
    
    %%% Test for interior, exterior polygons; set counterclockwise, clockwise orientation
    %set(axm,'XLim',[min(cellfun(@min,xs)) max(cellfun(@max,xs))],'YLim',[min(cellfun(@min,ys)) max(cellfun(@max,ys))]);
    %    % TEMPORARILY set axis limits to this
    %for pid=1:npids
    %    n_circum_ctours = 0;
    %    for pid_outer=[1:(pid-1) (pid+1):npids]
    %        if all(inpolygon(xs{pid},ys{pid},xs{pid_outer},ys{pid_outer}));
    %            n_circum_ctours = n_circum_ctours+1; break; % all vertices of one closed contour are contained in another; it is "interior"
    %        end
    %    end
    %    if mod(n_circum_ctours,2)==1
    %        [xnew, ynew] = poly2ccw(xs{pid},ys{pid});
    %    else
    %        [xnew, ynew] = poly2cw(xs{pid},ys{pid});
    %    end
    %    xs{pid} = xnew; ys{pid} = ynew; % note that "inpolygon" is indifferent to vertex ordering.
    %end
        % Edit: Again, clockwise/counterclockwise orientation should already be set by contour. Also have moved this content to 
        % mypoly2fv. poly2fv didn't work with "coast" lines, which perhaps were all clockwise/counterclockwise oriented.
        % mypoly2fv works by determining the number of vertices "inside" other groups of vertices.
    
    %% Make patches allowing for "holes" using poly2fv
    % We call patch ONCE to handle coherent contours and holes within, gaps, etc. and AGAIN
    % for each individual contour for the edge properties.
    % Face
    [F, V] = poly2fv(xs, ys);
    phands = patch('Faces',F, 'Vertices',V); % by default, no edges
    set(phands, patchargs); set(phands,'EdgeColor','none'); % set patch properties. re-enable edgecolor if you wish
    setfunc(axm, x_limkey,x_lim, y_limkey,y_lim); % reset axis limits
    % Edges
    edgehands = gobjects(1,length(xs));
    for i=1:length(xs); % can't use "XData, "YData" because they have different number of vertices
        edgehands(i) = patch('XData',xs{i},'YData',ys{i});
    end    
    set(edgehands, patchargs); set(edgehands,'FaceColor','none'); % face is empty
    phands = [phands(:)' edgehands(:)']; % concatenate them

    return
    
function [xfix] = lonmonotonic(x)
    %% Fix longitude indexing
    % Contourm has issues with operating in (mod 360); if you cross a
    % zero-line, contours run to center. Enforce monotonic indexing to fix this.
    switchdir = find(diff(x)<=0);
    minus = true;
    if numel(switchdir)>1
        error('Should only be one break from "monotonicity" of longitudes. We found more.');
    else
        xfix = x;
        if minus
            xfix(1:switchdir) = x(1:switchdir) - 360;
        else
            xfix(switchdir+1:end) = x(switchdir+1:end) + 360;
        end
    end

