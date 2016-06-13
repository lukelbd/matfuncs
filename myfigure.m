function [ varargout ] = myfigure( figtype, varargin )
    % My function for setting custom figure sizes (in inches) and axes positions within the figure.
    %
    % Usage: [fh, ax, chb, cht] = myfigure( figtype, varargin )
    %
    % Required Input:
    %   figtype: string code for type of figure.
    % Optional Input:
    %   ('nsub', nsub): number of subplots. default is 1, but some figtypes have option for more than one.
    %   ('nhemi', nhemi): number axes to set up for map axes, e.g. a south polar and north polar view (2), or just north polar (1).
    %   ('bigtitle'): add room for 2-LINE title.
    %
    % Important Note: All colorbars are made with a corresponding (peer) axis beneath them so that custom myxlabel, myylabel can be used; 
    % then in operation, just sync the CLim of the background axis and the axis on which you actually plot. 
    % Why do we do this? 2 reasons:
    % 1) Matlab DELETES AUTOMATICALLY existing colorbars associated with a given axis after
    %       you use pcolor or pcolorm (can't disable this behavior). So, having the colorbar
    %       be independent can be useful.
    % 2) text.m can't be used with a colorbar handle. For custom labels axis/tick labels, need axis handle.
    %
    % Figtype table:
    % 'basic': outputs [figh, axh]
    % '[x][y]mean', or '[x][y]corr': outputs [figh, main_axhs, cbarhs, cbar_axhs, vpanel_hs, hpanel_hs].
    %           single plot or side-by-side subplot of data with time on y axis. to the right, 
    %           vertical panels for extra info or horizontal panels on top.
    % 'display': outputs [figh, hovmol_axhs, cbarhs, cbar_axhs, meanpanel_hs, axm1_hs, axm2_hs].
    %           display means in several relevant dimensions.
    %           use with 'nsub', nsub for (nsub) rows and 'nhemi', (1 or 2) for (1 or 2) map axes, 
    %           e.g. NH and SH projections
    % 'video': outputs [figh] ....... finish this

    %% Note: should allow input of "sample y axis labels" so that we can figure out their
    %% eventual length. Then we will adjust size of plot based on that. Otherwise, use the "guess" values in mymargins.

    %% Note correct order of action: 1) Create figure
    %% 2) Create plots.
    %% 3) Modify axes according to default properties.
    %% 4) Apply all labels.


    %% Screen size
    set(0,'Units','pixels'); sz1 = get(0,'screensize'); set(0,'Units','inches'); sz2 = get(0,'screensize');
    xres = sz1(3)/sz2(3); yres = sz1(4)/sz2(4);
    %fprintf('Screen resolution: %ddpi X, %ddpi Y\n', xres, yres);
    
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
    
    %% Get margin widths/offsets using mymargins.m
    if strcmp(figtype,'movie'); fontsizegroup = 'movie'; else; fontsizegroup = 'print'; end
    gr = fontsizegroup;
    % Outside edges 
    dl = mymargins('left','figstyle',gr);
    db = mymargins('bottom','figstyle',gr);
    dt = mymargins(topstr,'figstyle',gr);
    dr = mymargins('right','figstyle',gr);
    % Subplot gaps (for plots both with/without labels); margin "edgesp" around all objects
    dsepsmall = mymargins('subpsmall','figstyle',gr);
    dsepbig = mymargins('subpbig','figstyle',gr);
    edgesp = mymargins('edgespace','figstyle',gr);
    dbint = (db-edgesp)+dsepsmall; dlint = (dl-edgesp)+dsepsmall; % for labels on subplots. otherwise db and dl add "edgespace" between axis label and figure wall;
        % but here instead of that edgespace we want standard/characteristic subplot separation space
    dlnolab = mymargins('leftnolab','figstyle',gr);
    dbnolab = mymargins('bottomnolab','figsytle',gr);
    dlint_nolab = (dlnolab-edgesp)+dsepsmall; dbint_nolab = (dbnolab-edgesp)+dsepsmall;
    
    % Extra space for special time axes
    if xtimeflag; db = mymargins('bottom','time','figstyle',gr); end
    if ytimeflag; dl = mymargins('left','time','figstyle',gr); end
    
     % Space for colorbar+its tick/axis labels (note: should allow for "label-less" colorbar perhaps)
    cbarwidth = mymargins('cbarwidth','figstyle',gr);
    cbar_yspace = cbarwidth+db; % extra space for colorbars
    cbar_xspace = cbarwidth+dl;
    % Special 
    
    %% Manual override of automatic figure sizing
    orig = [8 1];
    if fix_figsize_switch
        figsz = sizefix;
        switch fix_figsize_units
        case 'pixels' % convert to "inches" units; all of my custom plot functions are build around setting positions in "inches"
            figsz = [figsz(1)/xres figsz(2)/yres];
        end
    end  
    
    %% Create figure; get figure width
    fmake = @(figsz)figure('PaperPositionMode','auto', ...
            'Units','inches', ...
            'Position',[orig figsz], ... % set position
            'Renderer','painters'); % for some ridiculous reason, Matlab thinks 
                % says "oh, the user probably won't mind if I save the figure as a bitmap image inside a file format
                % with vector graphics capabilities to save space"... so you have to explicitly specify "painters" renderer
    if ~fix_figsize_switch;
        if journalspecflag; w = mymargins('figsize',figarticlespan,journ); else w = mymargins('figsize',figarticlespan); end; 
    else
        w = figsz(1);
    end
    w = w*figwidthscale; % if user specified different span

    %% Make axes
    % Each axes will be defined at its lower-left corner, with the optional
    % ability to include top or right margins in that box.
    margax = @(box,r,t)(axes('Units','inches','Position',[box(1), box(2), box(3)-r, box(4)-t])); % ...
      % sets axis position according to "box" location (region holding axis and all plot labels) and desired margins. 
    quickax = @(box)(axes('Units','inches','Position',box)); % ...
        % no margins; give exact location
    quickcb = @(ax,box,orient)(colorbar(ax,orient,'YAxisLocation','right','XAxisLocation','bottom','Units','inches','Position',box)); % ...
    margcb = @(box,r,t,orient)(colorbar(orient,'YAxisLocation','right','XAxisLocation','bottom','Units','inches','Position',[box(1:2) box(3)-r box(4)-t])); % ...
        % for colorbar. need 'south', 'east', 'north', or 'west' for determining where tick labels fall, direction of gradient
        
    %% Start loop
    switch figtype
    case 'basic'
        % Make "basic" figure. Has option for trivially tiling data.
        % The other settings are for situations where we have multiple subplots, but generaly don't want to label 
        % several of the axes
        wall = w;;
        w = wall/tile(2); % "horizontal" tile
        if cbarflag; xlen = w-dl-edgesp-cbar_xspace; else; xlen = w-dl-edgesp; end 
        ylen = xlen*axheightscale; h = ylen+db+dt; 
        if panelflag; h = h + xlen*panelwidthscale + dsepsmall; end 
        
        hall = h*tile(1); % "vertical" tile
        figsz = [wall hall];
        fh = fmake(figsz);

        for ix=1:tile(2)
            for iy=1:tile(1)
                if panelflag
                    pan(iy,ix) = quickax([dl db xlen xlen*panelwidthscale]); 
                    corner = [dl db+panelwidthscale*xlen+dsepsmall]; 
                else
                    corner = [dl db]; 
                end
                box = [corner xlen ylen]; box(1) = box(1)+(ix-1)*w; box(2) = box(2)+(iy-1)*h;
                ax(iy,ix) = quickax(box);
                if cbarflag; 
                    chx = (ix-1)*w+dl+xlen+edgesp; cht(iy,ix) = quickax([chx corner(2) cbarwidth ylen]); set(cht,'Visible','off');
                    chb(iy,ix) = quickcb(cht(iy,ix),[chx corner(2) cbarwidth ylen],'east'); set(chb,'YAxisLocation','right');
                end
            end
        end
        varargout{1} = fh;
        varargout{2} = ax;
        if panelflag; varargout{3} = pan; end
        if cbarflag
            varargout = [varargout {chb cht}]; % colorbar, axis behind colorbar
        end
        axes(ax);

    case 'tcsummary' % summarize TCs. will be 3 histograms on top in row, then map on bottom (since equirectangular maps for given basin are long)
        % Make figure; set 
        if nhist<2 || nhist>3; error('Two options: lon and lat hists, with map below, or lon lat time hists, with map below. Set nhists to 2 or 3.'); end
        %dlint_nolab = dsepsmall; % comment out if you want
        xtotlen = w - dlint_nolab*(nhist-1) - dl - dr; histboxlen = xtotlen/nhist; 
        xlen_map = histboxlen*nhist + dlint_nolab*(nhist-1); ylen_map = xlen_map*axmheightscale;
        %h = dbnolab + dbint + ylen_map + dsepbig + histboxlen + dt;
        h = dbnolab + dbint + ylen_map + dsepsmall + histboxlen + dt;
        %ystart_hist = dbnolab + dbint + ylen_map + dsepbig; xstart_hist = dl;
        ystart_hist = dbnolab + dbint + ylen_map + dsepsmall; xstart_hist = dl;

        figsz = [w h];
        fh = fmake(figsz);

        % Axes
        ax(1)=quickax([xstart_hist ystart_hist histboxlen histboxlen]); % hist 1
        ax(2)=quickax([xstart_hist+histboxlen+dlint_nolab ystart_hist histboxlen histboxlen]); % hist 2
        if nhist==3; ax(3)=quickax([xstart_hist+histboxlen*2+dlint_nolab*2 ystart_hist histboxlen histboxlen]); end % hist 3
        % Map axes
        axm=quickax([dl dbnolab  xlen_map ylen_map]);
        varargout{1} = fh;
        varargout{2} = ax;
        varargout{3} = axm;

    case {'xmean', 'xymean', 'ymean', 'xcorr', 'ycorr', 'xycorr'} % plotbox aspect ratios are pre-set.
        % Pcolor plots or subplots, with panels on y or x axis for e.g. means
        % Get boxes (each box = [left boundary, right boundary, x extent, y extent])
        % Find diagram in notes; should make this stuff clear. 

        %%%%
        %%%% CHANGE THIS???
        %%%% vvvv
        
        %% Figure / axis allocation    
        % Set starting points, spans in X for each axes
        vflag = true;
        switch figtype
        case {'xmean','xymean'} % 2 vertical panels
            xtotlen = w-dl-dr-dsepsmall*nsub-dsepbig*(nsub-1);
            xlenbox = xtotlen/nsub; % WANT: x + panelwidthscale*x = xlenm
            xlenm = xlenbox/(1+panelwidthscale); 
            panelwidth = xlenm*panelwidthscale; xlenvp = panelwidth;
            xm = dl; xvp = xm+xlenm+dsepsmall;
            xm2 = xvp+xlenvp+dsepbig; xvp2 = xm2+xlenm+dsepsmall; 
        case {'xcorr','xycorr'} % 1 vertical panel
            xtotlen = w-dl-dr-2*dsepsmall; % WANT: 2*x + 2*panelwidthscale*x = xtotlen
            xlenm = xtotlen/(2+2*panelwidthscale); 
            panelwidth = xlenm*2*panelwidthscale; xlenvp = panelwidth;
            xm = dl; xm2 = xm+xlenm+dsepsmall; xvp = xm2+xlenm+dsepsmall;
        case {'ymean','ycorr'}
            vflag = false;
            xtotlen = w-dl-dr-dsepbig*(nsub-1);
            xlenm = xtotlen/nsub; xlenvp = 0;
            panelwidth = xlenm*panelwidthscale;
            xm = dl; xm2 = xm+xlenm+dsepbig;
        end
        % Set starting points, spans in Y for each axes
        xhp = xm; xhp2 = xm2; xlenhp = xlenm; % h-panels are aligned with main-plot x position
        if corrflag; xlenhp = xlenm*2+dsepsmall; end
        ylenm = xlenm*axheightscale; ytotlen = ylenm + panelwidth; 
        ylenhp = panelwidth; % 5:7 aspect ratio of Hovmoller plots; also, set h-panel is 2/9ths of main plot height
        hflag = true; 
        switch figtype
        case {'ymean','xymean'}
            figy = ytotlen+cbar_yspace+db+dsepsmall+dt;
            ym = cbar_yspace+db; yhp = ym+ylenm+dsepsmall; 
        case {'ycorr','xycorr'}
            figy = ytotlen+cbar_yspace+db+dbint+dt;
            ym = cbar_yspace+db; yhp = ym+ylenm+dbint;
        case {'xmean','xcorr'}
            hflag = false;
            figy = ytotlen+cbar_yspace+db+dt;
            ylenm = ytotlen; ylenhp = 0; % reset ylenm
            ym = cbar_yspace+db;
        end
        % Make figure
        yvp = ym; ylenvp = ylenm; % v-panels are aligned with main-plot y position
        figsz = [w figy];
        fh = fmake(figsz); % new y-position

        %% Draw axes
        hpan = gobjects(1,1); vpan = gobjects(1,1); % placeholder
        ax(1) = quickax([xm ym xlenm ylenm]);
        cht(1) = quickax([xm db xlenm cbarwidth]); set(cht(1),'Visible','off');
        chb(1) = quickcb(cht(1),[xm db xlenm cbarwidth],'south');
        if vflag; vpan(1) = quickax([xvp yvp xlenvp ylenvp]); end
        if hflag; hpan(1) = quickax([xhp yhp xlenhp ylenhp]); end

        if nsub==2 || corrflag
            ax(2) = quickax([xm2 ym xlenm ylenm]);
            cht(2) = quickax([xm2 db xlenm cbarwidth]); set(cht(2),'Visible','off');
            chb(2) = quickcb(cht(2),[xm2 db xlenm cbarwidth],'south');
            if ~corrflag
                if vflag; vpan(1) = quickax([xvp2 yvp xlenvp ylenvp]); end
                if hflag; hpan(1) = quickax([xhp2 yhp xlenhp ylenhp]); end 
            end
        end

        % Output
        varargout{1} = fh; % figure
        varargout{2} = ax; % axis
        varargout{3} = chb; % colorbar
        varargout{4} = cht; % axis behind colorbar (for x, y label)
        varargout{5} = vpan; % vertical panels
        varargout{6} = hpan; % horizontal panels

    case 'display' % various means/correlation coefficients. have to edit this now, for showing just spatial corr over time or means
        
        %% Figure
        mapbox = (w-dl-dsepsmall*(nhemi+2)-cbar_xspace)/(nhemi+2); % LHS label, subplot separations, RHS edge == size of subplot separations 
        figy = mapbox*nsub + db + dt*nsub + dsepsmall*(nsub-1);% + dsepbig*(nsub-1);
        figsz = [w figy];
        fh = fmake(figsz);
        
        %% Make axes
        xedge = dl; % space for time x-axis labels
        xtotlen = w-dl-cbar_xspace; 
        xlen1 = xtotlen*(2/(nhemi+2))*1/4; xlin1 = xedge+xlen1;
        xlen2 = xtotlen*(2/(nhemi+2))*3/4; xlin2 = xlin1+xlen2;
        xlen3 = xtotlen*(1/(nhemi+2)); xlin3 = xlin2+xlen3;
        xlen4 = xtotlen*(1/(nhemi+2));
        axm2 = []; yend = 0;
        for isub = 1:nsub
            if isub==1; yedge = db; else; yedge = dsepsmall; end; %dsepbig; end
            yleneach = mapbox+dt; % defined mapbox earlier, remember?
            ystrt = yend+yedge; yend = ystrt+mapbox+dt;
            box1 = [xedge ystrt xlen1 yleneach];
            box2 = [xlin1 ystrt xlen2 yleneach];
            box3 = [xlin2 ystrt xlen3 yleneach];
            box4 = [xlin3 ystrt xlen4 yleneach];

            p(isub) = margax(box1,dsepsmall,dt); % line plot
            ax(isub) = margax(box2,dsepsmall,dt); set(ax(isub),'YTickLabel',''); % Hovmoller diagram
            axm1(isub) = margax(box3,dsepsmall,dt); set(axm1(isub),'Visible','off'); % map 1
            cpos = xedge+xtotlen; clen = yleneach-dt;
            if nhemi==2
                axm2(isub) = margax(box4,dsepsmall,dt); set(axm2(isub),'Visible','off'); % map 2
            end
            loc(isub,:) = [cpos ystrt cbarwidth clen]; 
            cht(isub) = quickax(loc(isub,:)); set(cht(isub),'Visible','off'); axes(cht(isub));
            chb(isub) = quickcb(cht(isub),loc(isub,:),'east'); 
            if nsub==2 && ~bigtitle; set(chb(isub),'YAxisLocation','right'); end
            if nsub>2 && bigtitle; set(chb(isub),'YAxisLocation','right'); end
                % for some INEXPLICABLE (!!!) reason, Matlab think left is "out" when you have no more, and no less than TWO rows
                % variables. I tried everything. simple solution: set axis location to "in." And when I use two rows of title lines, it's
                % different again.... revisit this
        end

        %% Output
        varargout{1} = fh; % figure
        varargout{2} = ax; % Hovmoller axis
        varargout{3} = chb; % colorbar
        varargout{4} = cht; % axis behind colorbar (for x, y label)
        varargout{5} = p; % mean panel
        varargout{6} = axm1; % axesm 1
        varargout{7} = axm2; % axesm 2

        %%%% ^^^
        %%%% CHANGE THIS???
        %%%%

    case 'movie' % for videos of mapaxes
        %% Figure
        h = mymargins('figsize','movie'); % right now, 1080p; here set *vertical* axis
        h_inches = h/yres; % have pixels/(dots/inch) --> inch ("dot" is just pixels)
        mapbox = (h_inches - cbar_yspace - dt - dsepsmall*(nhemi-1) - dsepsmall)/nhemi; % dsepsmall in vertical, dsepbig in horizontal. also dsepsmall separates mapaxes from colorbar.
        figx = mapbox*nsub + dsepbig*(nsub-1) + edgesp*2;
        figsz = [figx h_inches];
        fh = fmake(figsz); set(fh,'Renderer','opengl');
        
        %% Axes
        xstrt = edgesp + [0:nsub-1]*(mapbox + dsepbig);
        ystrt = cbar_yspace + dsepsmall + [0:nhemi-1]*(mapbox + dsepsmall);
        ax = gobjects(nhemi,nsub); cht = gobjects(1,nsub); chb = gobjects(1,nsub);
        for isub=1:nsub; for ihemi=1:nhemi;
            ax(ihemi,isub) = quickax([xstrt(isub) ystrt(ihemi) mapbox mapbox]);
            if ihemi==1
                cht(isub) = quickax([xstrt(isub) db mapbox cbarwidth]);
                chb(isub) = quickcb(cht(isub),[xstrt(isub) db mapbox cbarwidth],'south');
            end
        end; end
        set(ax,'Visible','off'); set(cht,'Visible','off');

        %% Output
        varargout{1} = fh; % figure
        varargout{2} = ax; % array of axes
        varargout{3} = chb; % colorbar
        varargout{4} = cht; % axis behind colorbar (for x, y label)
    end
    fprintf('Figure size: %d by %d inches.\n',figsz(1),figsz(2));
end
