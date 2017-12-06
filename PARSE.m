function [ varargout ] = myparse( func, args )
    % My plotting library was getting unweildly, and I want ability to pass
    % arguments between functions with ease (especially e.g. mymargins), so this
    % function will handle input parsing of ALL OTHER functions.
    %
    % I am aware if inputParser and associated methods, but prefer instead to use varargin 
    % with switches and assert.m for verification. inputParser is newish
    % (introduced 2007) and has some obscure syntax. switch case is more
    % user-friendly.
    % Devil's advocate: validatestring seems super useful (allows partial case
    % insensitive matches and has special error formatting); can't do that with
    % switch case method. Maybe will use new parsing scheme. Note the two main
    % methods: addRequired and addOptional are POSITIONAL, meaning their
    % position matters (note several build-in functions have this syntax). 
    % would use addParameter, but FATAL FLAW: cannot just input "switches", i.e.
    % SINGLE optional input variables that Matlab implicitly recognizes. so this workflow is
    % too rigid, and we WILL INDEED continue using switches, etc.. but, now you can read 
    % functions that do use inputParser. Sample of how it's used is below:
    %
    %p = inputParser; % here want keepunmatched to be false
    %validfuncs = {'mymargins','myset','myfigure','myposfix','mytick','mytitle','myxlabel','myylabel','mylegend','mymarker'};
    %checkinp = @(x)~isempty(validatestring(x,validfuncs));
    %addRequired(p,'func',@checkinp);
    %addRequired(p,'args',@iscell);
    %parse(p,func,args);
    %s = p.Results; func = s.func; args = s.args;
    %
    % OUTLINE: for each function, will parse varargin using 

    %% Now parse each
    exitstatus = 0;
    while exitstatus==0
        if iscell(func); funcloop = 1:length(func); end
        %% Loop through requested parsing routines
        for f=funcloop
            if iscell(func); ifunc = func{i}; else; ifunc = func; end
            switch ifunc

            %% Parse myset.m inputs
            case 'myset'
                func = {'mymargin','mytick','myticklabel','mytick'};
                %% Defaults
                d.box = 'on'; d.type = 'ax'; d.tickdir = 'both'; 
                d.latr = [-90 90]; d.lonr = [-180 180]; d.plabsp = 10; d.mlabsp = 30; % for flat axesm plots
                d.mlinelocs = [-150:30:180]; d.mlabmers = [ -150 -120 -60 -30 ]; % for polar axesm plots"
                d.landcolor = 'none'; d.oceancolor = 'w'; % default is no land/ocean color
                deflandcoloron = [.9 1 .6]; oceancoloron = [.85 .95 1]; % enable these if user says "landcolor" or "oceanlandcolor"
                
                d.xleftmult = false; d.ybottmult = false; d.yesnomult = 'yesmult'; % location of axis multiplier
                d.nhflag = false; d.shflag = false; % for polar projection
                d.geolab_format = 'signed'; % default
                d.xlonflag = false; d.ylonflag = false;
                
                d.timetype = 'monthday'; d.xtimeflag = 0; d.ytimeflag = 0; % time axis flags, and default
                
                d.axstruct = struct(); % initialize structure for passing arguments to "set" and "setm"
                d.noyticklab = 0; d.noxticklab = 0; % no tick labels
                d.axvec_4cbar = zeros(size(axvec)); % filler; root (0) is not "object".
                %d.axvec_undercbar = zeros(size(axvec)); % filler; root (0) is not "object".
              
                %% Parse
                argid = 1; marginpass = {};
                while argid<=length(varargin)
                    arg = varargin{argid};

                    %% Special
                    if isobject(arg) % the axis underneath "colorbar"; used to create custom text labels for colorbar, since colorbar can have no children (awww)
                        axvec_4cbar = arg;
                        assert(all(size(axvec)==size(axvec_4cbar)),'For EACH colorbar handle, in same array shape, need corresponding axis under colorbar.'); end
                        varargin(argid) = []; continue
                    end
                    if isstruct(arg); % structure-format name-value pairs to pass to "set" or "setm"
                        fieldnm = fieldnames(arg);
                        for i=1:length(fieldnm)
                            axstruct.(fieldnm{i}) = arg.(fieldnm{i});
                        end
                        varargin(argid) = []; continue
                    end

                    %% Switches and N-V pairs
                    switch lower(arg)
                    %% Axis type, figure type (figure type determines font size family)
                    case {'ax','cbar','axmpolar','axmflat'}
                        d.type = arg; ndel = 1;
                    case 'figstyle' % is it a "print" figure or "movie"? different text size templates, and margin allocations.
                        marginpass = varargin(argid:argid+1); ndel = 2; % will pass the N-V pair

                    %% Grids, box on/off, map backgrounds
                    case 'gridcolor' % custom gridcolor, gridstle, gridalpha
                        gridcolor = varargin{argid+1}; ndel = 2;
                    case 'gridstyle'
                        gridstyle = varargin{argid+1}; ndel = 2;
                    case 'gridalpha'
                        gridalpha = varargin{argid+1}; ndel = 2; % these are all applied to *custom* grid lines made with patchline
                    case 'landcolor' % landcoloron = 'none'
                        d.landcolor = landcoloron; ndel = 1; % colorize just land
                    case 'landoceancolor'
                        d.landcolor = landcoloron; d.oceancolor = oceancoloron; ndel = 1; % colorize land AND oceans
                    case 'boxon' % need to command Box on or off with this, because determines how axis position is adjusted
                        box = 'on'; ndel = 1;
                    case 'boxoff'
                        box = 'off'; ndel = 1;
                    case {'xgridoff','xgridon','ygridoff','ygridon'}
                        axstruct.([upper(arg(1)) 'Grid']) = lower(arg(6:end));

                    %% Map label spacing, lon/lat limits, label formats
                    case 'latrange' % optional for axmflat
                        latr = varargin{argid+1}; ndel = 2;
                    case 'lonrange' % optional for axmflat
                        lonr = varargin{argid+1}; ndel = 2;
                    case 'plabelspace' % optional for axmflat
                        plabsp = varargin{argid+1}; ndel = 2;
                    case 'mlabelspace' % optional for axmflat
                        mlabsp = varargin{argid+1}; ndel = 2;
                    case {'signed','compass','cardinal'} % optional label geolab_format
                        if strcmpi(arg,'cardinal'); geolab_format = 'compass'; end % for some reason switch is named "compass" in Matlab, even though cardinal
                            % makes way more sense. user can declare either.
                        geolab_format = arg; ndel = 1;

                    %% POLAR map axis considerations
                    case {'nh','sh'} % required for axmpolar
                        if strcmpi(arg,'nh') % "i" means ignore case
                            mapbound = [20 90]; maporig = [90 -90]; % with center over North America
                            mlabpar = 20; plinelocs = 35:15:80;
                            plabmer = 90;
                            nhflag = true;
                        else
                            mapbound = [-90 -20]; maporig = [-90 90];
                            mlabpar = -20; plinelocs = -80:15:-35;
                            plabmer = 90;
                            shflag = true;
                        end
                        plabpars = plinelocs; ndel = 2;

                    %% Special treatment of axis ticklabels/ticks (e.g. for longitudes, map to range (-180, 180]; for latitudes, only tick on meaningful locations, special labels, etc.)
                    %% Switches for turning ticklabels off
                    case 'xlon' % x-axis longitudes
                        xlonflag = true; ndel = 1;
                    case 'ylon' % y-axis longitudes; format for degrees west, east
                        ylonflag = true; ndel = 1;
                    case 'xtime' % if one of axes is a "time axis", apply time labels with mytimelabels.m
                        xtimeflag = 1; ndel = 1;
                    case 'ytime'
                        ytimeflag = 1; ndel = 1;
                    case {'count','month','year','monthday','yearmonthday'} % generally is a N-V pair with "xtime" or "ytime", but 
                            % you don't have to declare type. monthday with datenum or datevec input is default.
                        timetype = arg; ndel = 1;
                    case {'xnormal','ynormal'}; ndel = 1; % filler
                    case 'yoff' % want to "turn off" x, y labels
                        axstruct.('YTickLabel') = ''; noyticklab = 1; ndel = 1; 
                    case 'xoff'
                        axstruct.('XTickLabel') = ''; noxticklab = 1; ndel = 1;
                    case {'xon','yon'} % for consistency with the above
                        ndel = 1;

                    %% Ticks, axis multipier options
                    case {'tickin','tickout','tickboth'}
                        tickdir = arg(5:end);
                        axstruct.('TickDir') = arg(5:end); ndel = 1;
                    case 'xleft' % put location of x axis multiplier on LEFT, instead of right (default)
                        xleftmult = true; ndel = 1;
                    case 'ybott' % y axis multiplier on BOTTOM, instead of left
                        ybottmult = true; ndel = 1;
                    case {'xright','ytop'} % for consistency
                        ndel = 1;
                    case {'nomult','yesmult'}
                        yesnomult = arg; ndel = 1; 

                    %% Pass remaining Name-Value pairs to set(ax, ...)
                    otherwise
                        axstruct.(lower(arg)) = varargin{argid+1}; ndel = 2;
                    end
                    varargin(argid:argid+ndel-1) = [];
                end
                if isfield(axstruct,'box'); box = axstruct.box; axstruct = rmfield(axstruct,'box'); end
            case 'mymargin'
                %% Parse; font-size "templates" for different figure styles ("figstyles")
                varargin = expandcells(varargin); % often pass arguments for mymargins through the other functions. easiest way to do this is to just pass cell array "varargin" on through. 
                defaultflag = true; movieflag = false;
                switchfind = cellfun(@(x)strcmp(x,'figstyle'),varargin); 
                % for publications, posters
                abcsizenum = 10; % size for e.g. (a), (b) subplot identifier for caption
                bigsizenum = 8;
                smallsizenum = 7.5;    
                % for movies, online publishing
                if any(switchfind);
                    id = find(switchfind);
                    switch varargin{id+1};
                    case 'online' % add this???
                    case 'powerpoint' % add this??? 
                        % powerpoints are 10in by 7.5in default, so ideal font sizes should be same; 
                        % but maybe just add some width classes like 1slide, .5slide, etc. with that in mind
                    case 'movie' % for movies, different paradigm.
                        abcsizenum = 12;
                        bigsizenum = 10;
                        smallsizenum = 9;
                        defaultflag = false; movieflag = true;
                    case {'pub','print'} % "default"
                    otherwise
                        error('Unknown figure type: %s',varargin{id+1});
                    end
                    varargin(id:id+1) = [];
                end
            case 'myfigure'
                %% Default settings, and parse input
                fix_figsize_units = 'inches'; fix_figsize_switch = false; fix_figarticlespan_switch = false; journalspecflag = false;
                nsub = 1; nhemi = 1; 
                tile = [1 1]; cbarflag = false; panelflag = false; % options for "basic"
                topstr = 'top'; bigtitle = false; % changes if "bigtitle" is input  

                corrflag = false; switch figtype; case {'xcorr','ycorr','xycorr'}; corrflag = true; nsub = 2; end % default is 2 for this
                xtimeflag = false; ytimeflag = false; %switch figtype; case {'xmean','xymean','ymean','xcorr','xycorr','ycorr'}; ytimeflag = true; case 'display'; xtimeflag = true; end % defaults    
                    % probably better to specify if we are dealing with a time axis MANUALLY
                figarticlespan = '1col'; switch figtype; case {'basic','xcorr','ycorr','xycorr','xmean','xymean','ymean'}; if nsub==2; figarticlespan = '2col'; end; case 'display'; figarticlespan = '2col'; end % default spans
                nhist = 3; axmheightscale = .5; % if global projection, have 180 points vertically, 360 horizontally; scale is .5
                panelwidthscale = .2; axheightscale = 1.2; figwidthscale = 1;  % 7/5 for hovmoller
                if ~isempty(varargin);
                    iarg = 1;
                    while iarg<=length(varargin) % varargin changes length each time
                        arg = varargin{iarg};
                        switch arg
                        case 'bigtitle' % string option
                            topstr = 'bigtop'; bigtitle = true; ndel = 1;
                        case 'xtime' % need special time labels
                            xtimeflag = true; ndel = 1;
                        case 'ytime'
                            ytimeflag = true; ndel = 1;
                        case 'figsize'
                            sizefix = varargin{iarg+1}; fix_figsize_switch = true; ndel = 2;
                            fprintf('Override figsize.\n');
                        case 'units' % units for custom size. default is inches.
                            fix_figsize_units = varargin{iarg+1}; ndel = 2;
                            fprintf('New units.\n');
                        case 'cbar' % option for "basic"; put colorbar on RHS
                            cbarflag = true; ndel = 1;
                        case 'panel' % orption for "basic"; add horizontal panel on bottom
                                % THIS IS DIFFERENT FROM XMEAN, YMEAN; colorbar is on right, and can't extend to multiple subplots
                            panelflag = true; ndel = 1;
                        case 'nsub' % option for "display", "movie", and "[x/y][mean/corr]"
                            nsub = varargin{iarg+1}; ndel = 2;
                        case 'nhemi' % option for "display" and "movie"
                            nhemi = varargin{iarg+1}; ndel = 2;
                        case 'nhist' % option for "tcplot"
                            nhist = varargin{iarg+1}; ndel = 2;
                        case 'tile' % option for "basic"
                            tile = varargin{iarg+1}; ndel = 2;
                        case {'1col','2col','long'} % size of figure in scientific journal in terms of the template LaTeX file column widths, text widths, etc.
                            fix_figarticlespan_switch = true; ndel = 1;
                            figarticlespan = arg;
                        case {'grl','cd'} % journal in question. default is grl (Geophysical Research Letters)
                            journ = arg; ndel = 1;
                            journalspecflag = true; % did user specify journal, or will we just use default stored in mymargins.m?
                        case 'axheightscale' % option for "basic", "tcplot", and others; sets aspect ratio
                            axheightscale = varargin{iarg+1}; ndel = 2;
                        case 'panelwidthscale' % ratio of panel width to width of axis height dimension
                            panelwidthscale = varargin{iarg+1}; ndel = 2;
                        case 'axmheightscale' % option for "tcplot"; equirec projection height w.r.t. width depends on limits
                            axmheightscale = varargin{iarg+1}; ndel = 2; 
                        case 'figwidthscale' % e.g. if you want to occupy "half of column", etc.; USE FOR VISUALIZATION: (...,'2col','figwidthscale',3)
                            figwidthscale = varargin{iarg+1}; ndel = 2;
                        otherwise
                            error('Unknown input: %s. Valid switches: settings -- %s; journals -- %s; sizetypes -- %s.',arg,strjoin({'bigtitle','xtime','ytime','figsize','units','cbar','nsub','nhemi','nhist','tile', ...
                                             'axheightscale','axmheightscale','figwidthscale'},','), ...
                                             strjoin({'grl','cd'},','),strjoin({'1col','2col','long'},',')); 
                        end
                        varargin(iarg:iarg+ndel-1) = [];
                    end
                end

            case 'myposfix'

            end
        end
    end
end

