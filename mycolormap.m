function [ cmap ] = mycolormap( key, nlev, varargin )
    % My saved NCL colormaps. Returns colormap array and sets figure to new
    % colormap.
    % Usage:    mycolormap( key, nlevels)
    %           mycolormap( key, nlevels, <option>).
    %           mycolormap( h, ... )
    %   -"key" is...
    %       1) name for colormap; see function for available options
    %       2) a size N by 3 numeric colormap; use this if you have a map, but
    %           want to modify it
    %   -"nlevels" is number of levels; linearly interpolates RGB values of
    %       native colormap to match this count; preserves "neutral" if present
    %   -"option" can be a "squish", "stretch", or "flip"; can also be a number
    %       from 0 to 10 indicating how *much* user wants to squish/stretch
    %       (number is called "Param")
    %   -use figure handle "h" as first arg to set that colormap; default 
    %       behavior sets CURRENT FIGURE colormap
    %
    %   NOTE when using "squish", user may want to set the colorbar X/YScale to
    %   logarithmic (which will also require custom X/YTick)
    %
    %   NOTE user will probably want to use "Param" between 0 and 3. colors 
    %   often start to get indistinguishable beyond 3, especially for squish;
    %   many colormaps have largest hue/value gradient near low/mid levels,
    %   and weak gradients at high levels
    %

    %% Check for handle arg, verify input
    if ishandle(key),
        assert(strcmpi(get(key,'type'),'figure'),'Handle must be for figure.');
        assert(nargin>=3,'Bad input.');
        h = key; key = nlev; nlev = varargin{1}; varargin(1) = [];
    else
        assert(nargin>=2,'Bad input.');
        h = gcf;
    end
    assert(isscalar(nlev),'Bad input; number of levs must be scalar.');
    assert(mod(nlev,floor(nlev))==0,'Level count must be integer.');
%    key, nlev

    %% Cmap locations
    % expect cmaps to be in SUBDIR called "cmaps" in same location as THIS FILE
    cmaploc = fileparts(mfilename('fullpath'));
        % mfilename returns executing .m-file directory
    cmaploc = [cmaploc '/cmaps/'];

    %% Weighting extremities/center
    % function to sample cmap heavily in EXTREME/HIGH values, or squish toward
        % "neutral"/low
    samplesquish = @(x,a)( (x-1+(exp(x)-x).^a) ...
                / ...
                ((exp(1)-1)^a) );
    % function to sample cmap heavily in NEUTRAL/LOW values, or stretch away
        % from "neutral"/low
    samplestretch = @(x,a)(1 - ... % flips function across line y=1
                (-x+(exp(1-x)-(1-x)).^a) ...
                / ...  % substitue "x" with "1-x" to flip in x
                ((exp(1)-1)^a) );

    %% Switches, defaults
    Param = 2; % default squish/squash Param; can range from 0 (LINE) to Inf
        % 2 is a good compromise
    Stretch = false; Squish = false;
    Flipmap = false;
    for iarg=1:length(varargin);
        arg = varargin{iarg}; Flag = false;
        if isscalar(arg) && isnumeric(arg), Param = arg;
        elseif ischar(arg)
            switch lower(arg) % manual overrides
            case 'flip', Flipmap = true;
            case 'stretch', Stretch = true;
            case 'squish', Squish = true;
            otherwise, Flag = true; % unknown switch
            end
        else, Flag = true;
        end
        assert(~Flag,['Unknown argument. Input key specifier, scalar' ...
            '"number of levels", or "min, max" for scaling maps with' ...
            'neutral point. Avalable switches: "flip", "stretch", "squish".']);
    end
    assert(~(Stretch && Squish),'Must choose "stretch" OR "squish".');
    assert(Param<=10,'For your own good, choose Param<=10.');
    % unnormalize "Param" to go from 0 to mathematically "true" chosen max
    Eqmax = 4; % subjectively enforced maximum stretch/squish range
    Param = Param*Eqmax/10; % solves "Param/10 = x/Eqmax"; new range [0 Eqmax]

    %% Colormaps
    Hascutoff = false;
    Hasneutral = false;
    if isnumeric(key)
        % User input their own colormap, and wants to interpolate/modify it
        assert(ndims(key)==2,'Bad input colormap.');
        assert(size(key,2)==3 && size(key,1)>1,'Bad input colormap.');
        cmap = key; % user inputted their own colormap
    else
        switch key
        % Simple black-and-white
        case 'bw'
            cmap = repmat([0:.01:1]',[1 3]);
        % Rainbows
        case 'rainbow' % one of the best
            cmap = dlmread([cmaploc 'WhiteBlueGreenYellowRed.rgb']);
            cmap = cmap./255;
        case 'jet'
            cmap = dlmread([cmaploc 'MPL_jet.rgb'], ' ', 2, 0); % has 128 colors, better than matlab's 64 colors
            Hasneutral = true; % sort of
        case 'softjet'
            cmap = dlmread([cmaploc 'MPL_rainbow.rgb'], ' ', 2, 0); % NEW
            Hasneutral = true; % sort of
        case 'funky' % NCV jaisnd
            cmap = dlmread([cmaploc 'NCV_jaisnd.rgb'], ' ', 2, 1);
            cmap = cmap(:,2:2:6)./255; 
                % is space delimited, with two spaces 
        case 'expo' % rainbow, with much bigger orangey-red section than blue. use for e.g. sparse, very big values
            cmap = dlmread([cmaploc 'hotres.rgb'], ' ', 2, 0);
            cmap = cmap/255;
        % Blue-reds: inactive
            %case 'coolwarm' % very soft blue to red; too muddy to use I think        
            %cmap = dlmread([cmaploc 'MPL_coolwarm.rgb'], ' ', 2, 0); % very muddy, but slow transition
        % Blue-reds: soft
        case 'bwr' % hard blue to red transition; much better than coolwarm, which is murky
            cmap = dlmread([cmaploc 'MPL_RdBu.rgb'], ' ', 2, 0);
            cmap= flipud(cmap); % this one's really good
            Hasneutral = true;
        case 'byo' % reddish-orange to blue
            cmap = dlmread([cmaploc 'MPL_RdYlBu.rgb'], ' ', 2, 0);
            cmap = flipud(cmap); % goes red to blue, so we flip.
            %case; cmap = dlmread([cmaploc 'cmp_b2r.rgb'], ' ', 2, 0); cm_rybsoft = flipud(cm_rybsoft);
                % here entries are right-justified tab. only way to read with dlmread (yet another weird, inconcistent behavior .m function 
                % thing) is by only inputting file name, not specifing delimiter, and starting from the beginning.
            Hasneutral = true;
        case 'bwo' % hot reddish-orange to blue, white in middle
            cmap = dlmread([cmaploc 'BlueWhiteOrangeRed.rgb']);
            cmap = cmap./255; % has white in middle, blue to light blue to white, yellow, red
            Hasneutral = true; 
        % Blue-reds: hard
        case 'br' % BlRe
            cmap = dlmread([cmaploc 'BlRe.rgb']);
            cmap = cmap./255; % red-blue very saturated, with sharp transition
            Hascutoff = true;
        case 'brsoft'
            cmap = dlmread([cmaploc 'BlueRed.rgb'], '', 1, 0);
            cmap = cmap./255; % NEW
            Hascutoff = true;
        case 'bo' % NEW
            cmap = dlmread([cmaploc 'BlueYellowRed.rgb']);
            cmap = cmap./255; % blue to orange/red, with SHARP transition in middle
            Hascutoff = true;
        case 'wbrw'
            cmap = dlmread([cmaploc 'WhBlReWh.rgb'], '', 1, 0);
            cmap = cmap./255; % NEW
            Hascutoff = true;
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
            Hascutoff = true; 
        % Dry-wets
        case 'drywet'
            cmap = dlmread([cmaploc 'GMT_drywet.rgb'], ' ', 2, 0); 
        case 'cwt' % copper white turquois
            cmap = dlmread([cmaploc 'MPL_BrBG.rgb'], '', 2, 0); 
            Hasneutral = true; 
        case 'wgb' % very few levels
            cmap = dlmread([cmaploc 'CBR_wet.rgb'], '', 2, 0);
            cmap = cmap./255;
        case 'wgbv' % very few levels
            cmap = dlmread([cmaploc 'precip_11lev.rgb'], '', 2, 0);
            cmap = cmap./255;
        case 'bwgb' % brown white green blue
            cmap = dlmread([cmaploc 'precip_diff_12lev.rgb'], '', 2, 0);
            cmap = cmap./255;
            Hasneutral = true; 
        otherwise
            error('mycolormap:Input', ['Unknown colormap string: %s.' ...
                'Current valid options: %s.\n'], key, ...
                strjoin({'rainbow','jet','softjet','funky','expo','bwr', ...
                'byo','bwo','br','brsoft','bo','wbrw','night','drywet','cwt', ...
                'wgb','wgbv','bwgb'},', ')); 
        end
    end % if char, or otherwise
    % size
    N = size(cmap,1);

    %% Flip, return whether this has neutral or cutoff
    if Flipmap; cmap = flipud(cmap); end

    %% Modify map for "neutral" or "cutoff" override
    % Cutoff
    if Hasneutral && mod(nlev,2)==0, error('Choose odd number of levels for this map.');
    elseif Hascutoff && mod(nlev,2)==1, error('Choose even number of levels for this map.');
    end

    %% Initial interpolation
    if Hascutoff % interpolate each side separately
        assert(mod(N,2)==0, ...
          'Colormap with "cutoff" has odd-number of levels. Check its file.');
        oldptslo = 1:N/2;
        oldptshi = N/2+1:N;
        newptslo = linspace(1,N/2,nlev/2);
        newptshi = linspace(N/2+1,N,nlev/2);
        cmap = cat(1,interp1(oldptslo,cmap(oldptslo,:),newptslo), ...
                     interp1(oldptshi,cmap(oldptshi,:),newptshi));
    else % interpolate together even if hasneutral; don't need to preserve
      % colors on either side of the midpoint, and we already sample midpoint
      % since we enforce it to have odd number of levels
        newpts = linspace(1,N,nlev); %1:N/nlev:N;
        oldpts = 1:N;
        cmap = interp1(oldpts,cmap,newpts,'linear');
    end

    %% Stretch or squish on either side of midpoint
    if Squish, func = samplestretch; end
    if Stretch, func = samplesquish; end
    if Stretch || Squish
        % neutral/cutoff options (apply sampling weight to either side)
        if Hasneutral || Hascutoff
            % get ids for each branch of colormap
            if Hasneutral, loids = 1:(nlev-1)/2+1; hiids = (nlev-1)/2+1:nlev;
                % for Hasneutral, include midpoint in both runs
            else, loids = 1:nlev/2; hiids = nlev/2+1:nlev;
            end
            % now re-sample (interpolate onto new ids weighted toward extreme/
            % neutral values); must normalize ids
            locmap = flipud(interp1(normalize(loids), ...
                flipud(cmap(loids,:)), func(normalize(loids),Param)));
            hicmap = interp1(normalize(hiids), ...
                cmap(hiids,:), func(normalize(hiids),Param));
            % and put back together; NOTE extreme/neutral values should be same
            if Hasneutral, cmap = cat(1,locmap(1:end-1,:),hicmap);
            else, cmap = cat(1,locmap,hicmap);
            end
        % normal options
        else
            nids = normalize(1:nlev);
            cmap = interp1(nids,cmap,func(nids,Param));
        end
    end

    % ...and write
    set(h,'ColorMap',cmap);

end
