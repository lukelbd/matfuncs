function [ cmap, newclim, hascutoff] = mycolormap( type, varargin )
    % My saved NCL colormaps. Returns just array. Use colormap(mycolormap(...)) to set it up.
    % Usage: mycolormap( type, [ nlevels ]). Default uses native file levels; otherwise, linearly interpolates along array.
    %
    % Note on dlmread: It is intelligent; you don't always have to specify delimeter if alrady aligned on columns, but variable spaces or
    % tabs, etc.

    %% Cmap locations
    dirs = dict_filesys(); cmaploc = dirs.cmaps;  
    %dirs = myfilesys(); cmaploc = dirs.cmapdir;

    %% Switches, defaults
    nlev = 20; % default interpolation
    minmidmax = [-1 0 1]; newclim = [0 1];
    hasneutral = false; % if true, want small margin in middle to be "neutral"; not significantly positive or negative
    hascutoff = false; % if true, want prefect threshold from positive to negative
    flipmap = false;
    interpflag = true; % by default, turn interpolate on; but some we should enforce NO interpolation, e.g. if colormap has special levels
    for iarg=1:length(varargin);
        arg = varargin{iarg}; flag = false;
        if isscalar(arg);
            nlev = arg;
        elseif isnumeric(arg) && (length(arg)==2||length(arg)==3) && ndims(arg)==2
            minmidmax = arg;
            if length(arg)==2; minmidmax = [minmidmax(1) 0 minmidmax(2)]; end % default has 0 as "zero point/mid point"
        elseif ischar(arg)
            switch lower(arg) % manual overrides
            case 'flip'
                flipmap = true;
            case 'hasneutral'
                hasneutral = true;
            case 'hascutoff'
                hascutoff = true;
            otherwise
                flag = true; % unknown switch
            end
        else; flag = true;
        end
        if flag; error('Unknown argument. Input type specifier, scalar "number of levels", or "min, max" for scaling maps with neutral point. Avalable switches: "flip", "hasneutral", "hascutoff".'); end
    end
    if ~isempty(varargin); nlev = varargin{1}; end
    if hasneutral && hascutoff; error('Do not turn on both "hasneutral" and "hascutoff". Pick one or the other!'); end

    %% Colormaps
    switch type
    % Rainbows
    case 'rainbow' % one of the best
    	cmap = dlmread([cmaploc 'WhiteBlueGreenYellowRed.rgb']); cmap = cmap./255;
    case 'jet'
        cmap = dlmread([cmaploc 'MPL_jet.rgb'], ' ', 2, 0); % has 128 colors, better than matlab's 64 colors
    case 'softjet'
        cmap = dlmread([cmaploc 'MPL_rainbow.rgb'], ' ', 2, 0); % NEW
    case 'funky' % NCV jaisnd
    	cmap = dlmread([cmaploc 'NCV_jaisnd.rgb'], ' ', 2, 1); cmap = cmap(:,2:2:6)./255; 
            % is space delimited, with two spaces 
    case 'expo' % rainbow, with much bigger orangey-red section than blue. use for e.g. sparse, very big values
        cmap = dlmread([cmaploc 'hotres.rgb'], ' ', 2, 0); cmap = cmap/255;
    % Blue-reds: inactive
        %case 'coolwarm' % very soft blue to red; too muddy to use I think        
        %cmap = dlmread([cmaploc 'MPL_coolwarm.rgb'], ' ', 2, 0); % very muddy, but slow transition
    % Blue-reds: soft
    case 'bwr' % hard blue to red transition; much better than coolwarm, which is murky
        cmap = dlmread([cmaploc 'MPL_RdBu.rgb'], ' ', 2, 0); cmap= flipud(cmap); % this one's really good
        if ~hascutoff; hasneutral = true; end % can override one or the other
    case 'byo' % reddish-orange to blue
        cmap = dlmread([cmaploc 'MPL_RdYlBu.rgb'], ' ', 2, 0); cmap = flipud(cmap); % goes red to blue, so we flip.
        %case; cmap = dlmread([cmaploc 'cmp_b2r.rgb'], ' ', 2, 0); cm_rybsoft = flipud(cm_rybsoft);
            % here entries are right-justified tab. only way to read with dlmread (yet another weird, inconcistent behavior .m function 
            % thing) is by only inputting file name, not specifing delimiter, and starting from the beginning.
        if ~hascutoff; hasneutral = true; end % can override one or the other
    case 'bwo' % hot reddish-orange to blue, white in middle
        cmap = dlmread([cmaploc 'BlueWhiteOrangeRed.rgb']); cmap = cmap./255; % has white in middle, blue to light blue to white, yellow, red
        if ~hascutoff; hasneutral = true; end
    % Blue-reds: hard
    case 'br' % BlRe
        cmap = dlmread([cmaploc 'BlRe.rgb']); cmap = cmap./255; % red-blue very saturated, with sharp transition
        if ~hasneutral; hascutoff = true; end % can override one or the other
    case 'brsoft'
        cmap = dlmread([cmaploc 'BlueRed.rgb'], '', 1, 0); cmap = cmap./255; % NEW
    case 'bo' % NEW
        cmap = dlmread([cmaploc 'BlueYellowRed.rgb']); cmap = cmap./255; % blue to orange/red, with SHARP transition in middle
        if ~hasneutral; hascutoff = true; end
    case 'wbrw'
        cmap = dlmread([cmaploc 'WhBlReWh.rgb'], '', 1, 0); cmap = cmap./255; % NEW
        if ~hasneutral; hascutoff = true; end
    % Land: inactive; have no need for them right now, but when I do, should return cutoff levels for ocean vs. land, other colors...
    %case 'earth'
    %    cmap = dlmread([cmaploc 'MPL_terrain.rgb'], '', 2, 0); % NEW
            % should be modified; pay special attention to levels
    %case 'terrain'
    %    cmap = dlmread([cmaploc 'OceanLakeLandSnow.rgb']); cmap = cmap./255;
            % should be modified; pay special attention to levels
    % Land: active
    case 'night'
        cmap = dlmread([cmaploc 'GMT_nighttime.rgb'], ' ', 2, 0); % NEW
        if ~hasneutral; hascutoff = true; end
    % Dry-wets
    case 'drywet'
        cmap = dlmread([cmaploc 'GMT_drywet.rgb'], ' ', 2, 0); 
    case 'cwt' % copper white turquois
        cmap = dlmread([cmaploc 'MPL_BrBG.rgb'], '', 2, 0); 
        if ~hascutoff; hasneutral = true; end
    case 'wgb' % very few levels
        cmap = dlmread([cmaploc 'CBR_wet.rgb'], '', 2, 0); cmap = cmap./255;
    case 'wgbv' % very few levels
        cmap = dlmread([cmaploc 'precip_11lev.rgb'], '', 2, 0); cmap = cmap./255;
    case 'bwgb' % brown white green blue
        cmap = dlmread([cmaploc 'precip_diff_12lev.rgb'], '', 2, 0); cmap = cmap./255;
        if ~hascutoff; hasneutral = true; end
    otherwise
        error('mycolormap:Input', 'Unknown colormap string: %s. Current valid options: %s.\n', ...
            type, strjoin({'rainbow','jet','softjet','funky','expo','bwr','byo','bwo','br','brsoft','bo','wbrw','night','drywet','cwt','wgb','wgbv','bwgb'},', '));; 
    end

    %% Check colormap
    if hasneutral && mod(size(cmap,1),2)==0;
        midcols = size(cmap,1)/2; midcols = cmap(midcols:midcols+1,:);
        newmidcol = mean(midcols,1); % mean along 1st dimension is new "middle" color
        cmap = [cmap(1:size(cmap,1)/2-1,:); newmidcol; cmap(size(cmap,1)/2+2:end,:)];
        nlev = nlev+1;
        warning('Colormap has even number of default levels; no implicit zero point! Interpolating to assign a "midpoint".'); 
            % want for EVEN clim (e.g. -1, 1) an colormap color EXACTLY CENTERED about the zero, if it is "zero-type" colormap e.g. brown to green, blue to red.
            % then, will enforce number of non-zero levs on each side close to (0-min)*nlev/range on LEFT, (max-0)*nlev/range on RIGHT.  
    elseif mod(nlev,2)==1 && hascutoff; 
        cmap(floor(size(cmap,1)/2)+1,:) = []; 
        nlev = nlev-1;
        warning('Colormap has odd number of default levels; no implicit cutoff point! Removing "midpoint".');
    end
    
    % Flip, return whether this has neutral or cutoff
    if flipmap; cmap = flipud(cmap); end
    hasstuff = [hasneutral hascutoff];

    % Return now, if you don't want interpolation
    if ~interpflag; warning('Skipping interpolation.'); return; end

    % Initial interpolation
    newpts = linspace(1,size(cmap,1),nlev); %1:size(cmap,1)/nlev:size(cmap,1);
    oldpts = 1:size(cmap,1);
    cmap = interp1(oldpts,cmap,newpts,'linear');

    % If has zero point, apply special settings; modify number of steps between [min, mid-1] and [mid+1,max]
    % mycolormap.m will return the NEW cmap limits (BASED ON REQUESTED NLEV) that will perfectly place "zero"
    % in the middle if user sets 'CLim' to that 1by2 value.
    if (hascutoff || hasneutral) && (range(minmidmax(1:2))~=range(minmidmax(2:3))); % if color range already symmetric, don't bother
        nlev_nonzero = nlev-1; 
        if hascutoff; nlev_nonzero = nlev; end 

        maxmindiff = minmidmax(3)-minmidmax(1); 
        [~,maxside] = max([range(minmidmax(1:2)),range(minmidmax(2:3))]);
            % is NEGATIVE side "bigger" or POSITIVE side? for smaller side, choose CEILING so that nlev is not zero.
        
        nlev_minus = ceil(range(minmidmax(1:2))*nlev/maxmindiff); % make number of levels so that new clims will be made *ROOMIER* rather than constrained
        nlev_plus = ceil(range(minmidmax(2:3))*nlev/maxmindiff);
        newclim = [minmidmax(2)-nlev_minus*maxmindiff/nlev minmidmax(2)+nlev_plus*maxmindiff/nlev];
        if mod(nlev_minus+nlev_plus,2)==1; % add extra level onto the "bigger" side; will be less noticeable; e.g. if "negative" 
                % side is super tiny (1-2 colors) and add color, the new CLim will be thrown way off
            if maxside==1;
                nlev_minus = nlev_minus+1;
            elseif maxside==2;
                nlev_plus = nlev_plus+1;
            end
        end % need even total number of -ve, +ve
        if nlev_minus<5 || nlev_plus<5; warning('Very few colors on either side of zero. Specify more levels for more meaningful intervals.'); end

        % number of points, middle color
        if hasneutral
            midcol = cmap((nlev+1)/2,:);  
            lomax = floor(nlev/2); himin = ceil(nlev/2);
        else; 
            midcol = zeros(0,3);
            lomax = nlev/2-1; himin = nlev/2+1;
        end
        oldlowpts = 1:lomax; oldhipts = himin:nlev;
        newlowpts = linspace(1,lomax,nlev_minus); newhipts = linspace(himin,nlev,nlev_plus); 
        if nlev_minus==1; newlopoints = 1; end; if nlev_plus==1; newhipoints = nlev; end 
            % in case just have ONE COLOR on this side of zero, make it small. but note this is really not ideal; then data just below midpoint will be "white", but 
            % further below will turn to that color; zero point is really for some finite range of values, not just zero

        % interpolate
        lowcols = interp1(oldlowpts,cmap(1:lomax,:),newlowpts); hicols = interp1(oldhipts,cmap(himin:end,:),newhipts);
        cmap = [lowcols; midcol; hicols];
    end   

end
