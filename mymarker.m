function [ patchlines ] = mymarker( ax, xs, ys, varargin );
    % Creates custom marker from image file (must be located in MyPlotFuncs.m);
    % Assumes image is colored, and background is EMPTY or WHITE.
    %
    % Special note on patch objects: The patch "edge" line is always exactly centered on
    % the boundary of the frame. So, if you don't want "fuzzy" looking borders, 
    % NEVER use edgealpha<1 unless your facecolor is set to "none". Just doesn't look
    % good.
    %

    %% Parse input, initial stuff
    % defaults
    filenm = 'tropicalstorm.png'; transflag = true; flipflag = false; ftype = 'png';
    resize = 100; % 500
    markersize = mymargins('fatmarker'); % use default size by default
    % parse 
    patchargs = struct();
    iarg = 1;
    while iarg<=length(varargin)
        arg = varargin{iarg};
        if ischar(arg); 
            switch lower(arg)
            case {'tcthin','ntcthin','stcthin'} % these don't look as nice
                filenm = 'tropicalstorm.png'; ftype = 'png'; transflag = true; if ~strcmpi(arg,'stcthin'); flipflag = true; end
                varargin(iarg) = [];  % in MyPlotFuncs directory
            case {'tc','ntc','stc'}
                filenm = 'storm2.jpeg'; ftype = 'jpeg';  transflag = false; if strcmpi(arg,'stc'); flipflag = true; end
                varargin(iarg) = [];  % in MyPlotFuncs directory
            case 'markersize'
                markersize = varargin{iarg+1}; varargin(iarg:iarg+1) = []; 
            otherwise
                patchargs.(arg) = varargin{iarg+1}; varargin(iarg:iarg+1) = [];
            end
        elseif isnumeric(arg) && isscalar(arg)
            resize = arg; varargin(iarg) = [];
        else
            error('Unknown argument. Right now, we only allow a marker type identifier, and Name-Value pairs to be passed to PATCH.');
        end
    end
    if mod(length(varargin),2)==1; error('Bad input argument. Only accept marker type switch, and Name-Value pairs for patch.'); end
    if length(xs)~=length(ys); error('X and Y are not the same length.'); end

    %% Load image, filter
    if ~transflag;
        [rgb, ~] = imread(filenm,ftype); 
        dat = mean(double(rgb),3)./255; thresh = .95;
        dat(dat<thresh) = 0; dat(dat>=thresh) = 1; dat = 1-dat; % if it's "white enough", gets filtered out
        %max(dat(:)), min(dat(:)), max(rgb(:)), min(rgb(:)), size(rgb)
            % use the above for images with WHITE BACKGROUND. maps pixels to monochromatic between [0, 1]
    else
        [~, ~, transparency] = imread(filenm,ftype);   
            % use these for images with transparency
        dat = double(transparency)./255; dat(dat<1) = 0; % if "Alpha" less than 1 (i.e. has ANY transparency), set to zero.
    end
    if flipflag; dat = flipud(dat); end % for NH, arms should be on top-left and bottom-right 
    datsz = size(dat);
    if sum(dat(:)==0)==numel(dat); error('All points are zero!'); end

    %% Downsample (just use linear interpolation) -- important because we don't want a million vertices every time we draw the patch object!
    if datsz(2)>datsz(1) % x is longer; 
        xresize = resize; yresize = floor(resize*datsz(1)/datsz(2));
    else % y is longer
        yresize = resize; xresize = floor(resize*datsz(2)/datsz(1));
    end
    [X, Y] = meshgrid(1:datsz(2), 1:datsz(1)); [Xq, Yq] = meshgrid(linspace(1,datsz(2),xresize), linspace(1,datsz(1),yresize));
    dat = interp2(X, Y, dat, Xq, Yq); 
    dat(dat>=.5) = 1; dat(dat<.5) = 0; % and SET TO PERFECT MASK 
    datsz = size(dat); % reset -- NEW RESOLUTION
        %imagesc(dat), pause(2)

    %% Determine patch object vertices, and use MYCONTOUR2PATCH.M to get patch object.
    % y extent and x extent in pixels. use find with flatten -- more efficient than row-by-row searchng
    dat = dat(:); nonzero = find(dat>0); dat = reshape(dat,datsz); % much faster than using for loops
    yids = mod(nonzero-1,datsz(1))+1; % e.g. for 5by5 array, if id is 6, then "y" location is mod(6-1,5)+1 = 0+1 = 1 --> first entry in second column, etc.
    xids = ceil(nonzero/datsz(1)); % e.g. for 5by5 array, if id is 6, then "x" location is ceil(6/5) = ceil(6)/5 = 2. for 1, is 1, etc.
    xextent = range(xids); yextent = range(yids); [maxextent, id] = max([xextent yextent]);
        % and finally we arrange so that x/y id-spacing is transormed from 1 to (spacing such that x/yextent is <MARKERSIZE>, in poitns)
    dat = dat(min(yids):max(yids),min(xids):max(xids));
        %xextent, yextent, min(yids), max(yids), min(xids), max(xids), id
        %datsz = [yextent+1 yextent+1]; datsz, datsz = size(dat); dats,
    datsz = size(dat); % reset -- WE CUT OFF FRAME
        %imagesc(dat), pause(2)
    
    % axis conversion
    set(ax,'Units','inches');
    axpos = get(ax,'Position'); xlen = axpos(3); ylen = axpos(4);
    xlim = get(ax,'XLim'); ylim = get(ax,'YLim');
    markersize_inches = markersize/72; 
    if id==1 % x is longest
        inch_to_data = (xlim(2)-xlim(1))/xlen;
        inch_to_data_across = (ylim(2)-ylim(1))/ylen;
    elseif id==2 % y is longest
        inch_to_data = (ylim(2)-ylim(1))/ylen;
        inch_to_data_across = (xlim(2)-xlim(1))/xlen;
    end
    markersize_data = markersize_inches*inch_to_data;
    if id==1 % want xextent to == markersize_data, so EACH PIXEL is markersize_data/xextent APART
        newspacing = markersize_data/xextent;
        acrossspacing = newspacing*(inch_to_data_across/inch_to_data);%*(datsz(2)/datsz(1)); % is the spacing in "across" units, times the original aspect ratio
        y = min(ylim)+acrossspacing:acrossspacing:min(ylim)+datsz(1)*acrossspacing; x = min(xlim)+newspacing:newspacing:min(xlim)+datsz(2)*newspacing;
            % why "min"? just incase xdir or ydir is reverse... actually no, xmin and ymin is always in order. well, whatever.
    elseif id==2
        newspacing = markersize_data/yextent;
        acrossspacing = newspacing*(inch_to_data_across/inch_to_data);%*(datsz(2)/datsz(1)); % is the spacing in "across" units, times the original aspect ratio
        x = min(xlim)+acrossspacing:acrossspacing:min(xlim)+datsz(2)*acrossspacing; y = min(ylim)+newspacing:newspacing:min(ylim)+datsz(1)*newspacing;
    end
    xmid = (x(1)+x(end))/2; ymid = (y(1)+y(end))/2; 
        %max(x), max(y)
        %acrossspacing, newspacing, max(x), max(y)
        %size(x), size(y), size(dat)

    %% Draw contour, get template object
    % IMPORTANT; image is assumed to be stored in image indexing, so top of image is "first" in y dimension, bottom is "last". for contour, STILL each row is
    % a "y" index and each column is an "x" index, however bottom is at the "top"! use flipud for this. 
    [h, F, V, xpatch, ypatch] = mycontour2patch(ax, x, y, flipud(dat), .5, 'EdgeColor','k','FaceColor','k'); % not in meshgrid format
    delete(h); % F = get(h,'Faces'); V = get(h,'Vertices'); xdat = get(h,'XData'); ydat = get(h,'YData'); delete(h);
        % note EACH COLUMN in V is an x, y index. so to center on user input xs, ys, just subtract them for each point
    %for j=1:size(xdat,3); % should be same as ydata
    %    [xdat(:,j), ydat(:,j)] = poly2cw(xdat(:,j),ydat(:,j)); %ydat(:,j) = poly2cw(ydat(:,j));
    %end
    %size(xdat), size(ydat), max(xdat(:)), min(xdat(:)), max(ydat(:)), min(ydat(:))
    %max(V(:,1)), min(V(:,1)), max(V(:,2)), min(V(:,2))

    %% Finally, redraw object CENTERED on data in specified locations requested by user
    npts = length(xs);
    axes(ax); % now ax explicitly must be gca
    for i=1:npts
        %size(x), size(y)
        Vinsert = [V(:,1) + xs(i) - xmid, V(:,2) + ys(i) - ymid]; 
        %xdatnew = xdat + xs(i) - xmid; ydatnew = ydat + ys(i) - ymid;
        p=patch('Faces',F,'Vertices',Vinsert); % default
        set(p,patchargs); set(p,'Edgecolor','none','Marker','none'); % INSIDES. can't have "holes" without F, V format. but, then the edge lines go every which way, which is terrible.
            % so we draw TWO patches for each marker. the next one uses xdata and ydata directly, sorted clockwise, with linewidth properties.
        for j=1:length(xpatch);
            xinsert = xpatch{j} + xs(i) - xmid; yinsert = ypatch{j} + ys(i) - ymid;
            p=patch('XData',xinsert, 'YData',yinsert); %,'k'); % this way we don't have to specify color
            set(p, patchargs); set(p,'Facecolor','none','Marker','none'); % obviously don't want markers on edge of marker vertices
        end
    end

    %% Test
    if 0; % some details
        class(dat)
        sum(dat(:)==0)
        sum(dat(:)==1)
        min(dat(:))
        max(dat(:))
        size(dat) 
    end

end
