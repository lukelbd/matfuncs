function [ outax ] = myset( axvec, varargin )
    % Sets colorbar or plot axes to default properties, or creates 
    % axesm object within given axis. Can change some slightly from
    % default using varargin.
    %
    % Times: For timelabel, instead of inputting date vector, please input the dates/years/months
    % you WANT labeled, along with the type of label, and matlab will set the appropriate ticks for that type of label.
    % Just include "mon", "daymonthyear", etc. string so that it knows which to pick. timelabel will work by reading
    % the current ticks you set with 'xtick' and 'ytick' (for which you want labels), then apply new ticks with no labels on appropriate locations
    % (e.g. unique days, unque months, etc.), and modify the default datenum label to a date string. Makes sense, because what do I want
    % when I set a time axis? I want to choose ticks/have matlab automatically adjust them, then MODDIFY TICKS and tick labels
    % so they fall on relevant "months", "days", etc. 
    %
    % Note xticklabel and yticklabel won't work here; too ambiguous. Length of get(ax,'xticklabel') can be same as xtick, or same as *visible* xticks
    % and they just weren't reset... in general, confusing. If you need special tick labels that aren't determined automatically, add the functionality
    % here and to myticklabel. Use 'xtime' or 'ytime' for special time labels.

    %% Colors
    gridcolor = [0 0 0]; % for grid lines, oceans, etc.
    gridalpha = .5; gridstyle = ':'; mapgridstyle = ':';
    
    %% Defaults
    box = 'on'; type = 'ax'; tickdir = 'both'; 
    latr = [-90 90]; lonr = [-180 180]; plabsp = 10; mlabsp = 30; % for flat axesm plots
    mlinelocs = [-150:30:180]; mlabmers = [ -150 -120 -60 -30 ]; % for polar axesm plots"
    landcolor = 'none'; oceancolor = 'w'; % background
    deflandcolor = [.9 1 .6]; defoceancolor = [.85 .95 1]; % enable these if user says "landcolor" or "oceanlandcolor"
    
    xleftmult = false; ybottmult = false; yesnomult = 'yesmult'; % location of axis multiplier
    nhflag = false; shflag = false; % for polar projection
    geolab_format = 'signed'; % default
    xlonflag = false; ylonflag = false;
    
    timetype = 'monthday'; xtimeflag = 0; ytimeflag = 0; % time axis flags, and default
    
    axstruct = struct(); % initialize structure for passing arguments to "set" and "setm"
    noyticklab = 0; noxticklab = 0; % no tick labels
    axvec_undercbar = zeros(size(axvec)); % filler; root (0) is not "object".
  
    %% Parse
    argid = 1; marginpass = {};
    while argid<=length(varargin)
        arg = varargin{argid};

        %% Special
        if isobject(arg) % the axis underneath "colorbar"; used to create custom text labels for colorbar, since colorbar can have no children (awww)
            axvec_undercbar = arg;
            if all(size(axvec)~=size(axvec_undercbar)); error('For EACH colorbar handle, in same array shape, need corresponding axis under colorbar.'); end
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
            type = arg; ndel = 1;
        case 'figstyle' % is it a "print" figure or "movie"? different text size templates, and margin allocations.
            marginpass = varargin(argid:argid+1); ndel = 2; % will pass the N-V pair

        %% Grids, box on/off, map backgrounds
        case 'gridcolor' % custom gridcolor, gridstle, gridalpha
            gridcolor = varargin{argid+1}; ndel = 2;
        case 'gridstyle'
            gridstyle = varargin{argid+1}; ndel = 2;
        case 'gridalpha'
            gridalpha = varargin{argid+1}; ndel = 2; % these are all applied to *custom* grid lines made with patchline
        case 'landcolor' % landcolor = 'none'
            landcolor = deflandcolor; ndel = 1; % colorize just land
        case 'landoceancolor'
            landcolor = deflandcolor; oceancolor = defoceancolor; ndel = 1; % colorize land AND oceans
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
    
    %% Load settings from mymargins
    stringset_struct = mymargins('ax',marginpass);
    edgecolor = stringset_struct.color; 
    ticklens = mymargins('ticklen',marginpass);
    ticklens = repmat(ticklens,[numel(axvec) 2]);
    %% Loop
    axsz = size(axvec);
    axvec = axvec(:); axvec_undercbar = axvec_undercbar(:);
    outax = gobjects(1,length(axvec));
    for i=1:length(axvec);
        ax = axvec(i); ax_undercbar = axvec_undercbar(i);
        %% Convert ticklength units from pts to (normalized)
        axun = get(ax,'Units'); set(ax,'Units','inches');
        axpos = get(ax,'Position'); maxlen_inches = max(axpos(3:4)); % Matlab sets tick length in normalized units proportional to maximum of (x axis extent, y axis extent)
        ticklen_normal = ticklens(i,:)/maxlen_inches; % normalize the custom "tick length" units set in inches above.
        
        %% Line widths (load from mymargins)
        figh = get(ax,'Parent');
        lwcustom = mymargins('line',figh,marginpass);

        %% Delete all custom stuff
        if 0;textdel = {'XTickLabel','YTickLabel','XTickLabelMultiplier','YTickLabelMultiplier','XLabel','YLabel','MLabel','PLabel'};
        groupdel = {'XGrid','YGrid','Meridians/Parallels','Coast'}; patchdel = {'Coast'};
        for j=1:length(textdel); delete(findobj(ax,'Type','text','Tag',textdel{j})); end
        for j=1:length(groupdel); delete(findobj(ax,'Type','hggroup','Tag',groupdel{j})); end
        for j=1:length(patchdel); delete(findobj(ax,'Type','patch','Tag','Coast')); end
        end

        %% Adjust axis position if ticklength is set out or in, so that margin space allocation asumed by myfigure.m is exact and correct.
        % We do this BEFORE setting up text
        ticklen = ticklens(i,1); %_normal(1)*maxlen_inches; % convert back to scalar unit in inches
        switch type
        case 'ax'
            switch tickdir
            case {'out','both'}
                switch box
                case 'on'; newlen = [axpos(3)-2*ticklen axpos(4)-2*ticklen];
                otherwise; newlen = [axpos(3)-ticklen axpos(4)-ticklen];
                end
                set(ax,'Position',[axpos(1)+ticklen axpos(2)+ticklen newlen]);
            end
        case 'cbar'
            switch tickdir
            case {'out','both'}
                if hor; newpos = [axpos(1) axpos(2)+ticklen axpos(3) axpos(4)-ticklen]; % label on BOTTOM
                else; newpos = [axpos(1) axpos(2) axpos(3)-ticklen axpos(4)]; % label on RIGHT
                end
                set(ax,'Position',newpos);
            end
        end
        newpos = get(ax,'position'); ticklen_normal = ticklens(i,:)/max(newpos(3:4)); % new tick length

        switch type
        %% Axis properties
        case 'ax'
            set(ax,     'Box',          box,  ...
                        'Layer',        'top', ... % puts e.g. tick marks on top of objects
                        'TickDir',      tickdir, ...
                        'XColor', edgecolor, 'YColor', edgecolor, ... % post 2014a only I thought... but seems to work
                        'Units',        'inches', ...
                        'TickLength',   ticklen_normal, ... 
                        'YGrid',        'on',   ...
                        'XMinorTick',   'on',   ...
                        'YMinorTick',   'on',   ...
                        'LineWidth',    lwcustom);
            set(ax, axstruct); % my override settings
            % Set custom x, y labels
            
            %% Custom grid (default one acutaly DOES have alpha property, and sets it automatically very transparent (.15), 
            % but puts it in uistack at bottom... which defeats the purpose of choosing an Alpha<1)
            xl = get(ax,'XLim'); yl = get(ax,'YLim');
            xg = get(ax,'XGrid');
            if strcmp(xg,'on')
                set(ax,'XGrid','off');
                xt = get(ax,'XTick');
                g = hggroup('Parent',ax, 'Tag','XGrid');
                for j=1:length(xt)
                    if xt(j)>xl(1) && xt(j)<xl(2)
                        patchline([xt(j) xt(j)],yl,'LineWidth',lwcustom,'LineStyle',gridstyle,'EdgeColor',gridcolor,'EdgeAlpha',gridalpha, ...
                                    'Parent',g);
                    end
                end
            end
            yg = get(ax,'YGrid');
            if strcmp(yg,'on')
                set(ax,'YGrid','off');
                yt = get(ax,'YTick'); 
                g = hggroup('Parent',ax, 'Tag','YGrid');
                for j=1:length(yt)
                    if yt(j)>yl(1) && yt(j)<yl(2)
                        patchline(xl,[yt(j) yt(j)],'Linewidth',lwcustom,'LineStyle',gridstyle,'EdgeColor',gridcolor,'EdgeAlpha',gridalpha, ...
                            'Parent',g);
                    end
                end
            end
            set(ax,'YLim',yl,'XLim',xl);

            %% My time labels and tick labels
            if xtimeflag
                if noxticklab; timepass = 'noticklab'; else; timepass = 'yesticklab'; end
                mytimelabel(ax, 'x', timetype, timepass, marginpass);
            elseif ~noxticklab
                set(ax,'XTickLabelMode','auto'); % restore
                if xleftmult; multcode = 'xleft'; else; multcode = 'xright'; end
                if xlonflag; inp = 'lon'; else; inp = 'normal'; end
                xaxloc = get(ax,'XAxisLocation');
                if strcmpi(xaxloc,'top'); ticktype = 'xtop'; else; ticktype = 'x'; end
                    %ticktype, multcode, yesnomult, inp, marginpass
                myticklabel(ax, ticktype, multcode, yesnomult, inp, marginpass);
            end
            if ytimeflag
                if noyticklab; timepass = 'noticklab'; else; timepass = 'yesticklab'; end
                mytimelabel(ax, 'y', timetype, timepass, marginpass);
            elseif ~noyticklab
                set(ax,'YTickLabelMode','auto'); % restore
                if ybottmult; multcode = 'ybott'; else; multcode = 'ytop'; end
                if ylonflag; inp = 'lon'; else; inp = 'normal'; end
                yaxloc = get(ax,'YAxisLocation');
                if strcmpi(yaxloc,'right'); ticktype = 'yright'; else; ticktype = 'y'; end
                myticklabel(ax, ticktype, multcode, yesnomult, inp, marginpass);
            end
            outax(i) = ax;

        %% Colorbar properties
        case 'cbar'
            set(ax,         'LineWidth', lwcustom, ...
                            'TickDir', 'in', ...
                            'TickLength', ticklen_normal(1)); % ticklength is scalar for colorbar
                                % (frame/boundary color should always be synced with axis label color; looks weird otherwise...) 
            set(ax, axstruct); % my override settings
            
            % Set custom x, y labels (need "underlying axis" for this -- myfigure has several templates that do so). Also note: you will 
            % ALWAYS want colorbar with tick labels (unlike sometimes, for subplots, you don't). So the functionality where we ignore axes 
            % with empty '' units) doesn't make sense. Reset them before passing to myticklabel
            if axpos(3)>axpos(4); 
                hor = true; 
            else
                hor = false; 
            end
            if isobject(ax_undercbar)
                set(ax_undercbar,'Units','inches');
                if hor
                    xtick = get(ax,'XTick'); xl = get(ax,'XLim');
                    set(ax_undercbar,'XLim',xl);
                    set(ax_undercbar,'XTick',xtick,'XTickLabelMode','auto');
                    myticklabel(ax_undercbar, 'x', xtick, marginpass);
                else
                    ytick = get(ax,'YTick'); yl = get(ax,'YLim');
                    set(ax_undercbar,'YLim',yl);
                    set(ax_undercbar,'YTick',ytick,'YTickLabelMode','auto');
                    myticklabel(ax_undercbar, 'yright', ytick, marginpass);
                end
                set(ax,'XTickLabel','','YTickLabel','');
            else
                warning('Colorbar was not reset with custom ticks. To do so, set the CLim you want for the underlying axis and then include the underlying axis handle as a second input.');
            end
            outax(i) = ax;

        %% Axesm properties
        case {'axmpolar','axmflat'}
            stringset_struct.fontweight = 'bold'; % exception; really hard to see labels in midst of data if not bold
            axes(ax); % Strike #1: For some reason can't use axesm with axis handle input; must be selected beforehand, even though allowing gobject input would 
                % take literally ONE LINE. Matlab is full of surprises.
            set(ax,'Units','inches','Visible','off','TickDir','in'); % for safety, tickdir in... not really necessary 
            switch type
            case 'axmpolar'
                %% Polar azimuthal projections
                if ~nhflag && ~shflag; error('Must specify hemisphere for map plotting.'); end
                axesm('eqdazim', ...
                        'Origin',           maporig,        'MapLatLimit',  mapbound, ...
                        'Grid',             'on',  ... % they tend to overlap each other on really small subplot if you pick cardinal
                        'Frame',            'on',           'FEdgeColor',   edgecolor,      'FLineWidth', lwcustom, 'FFaceColor',oceancolor, 'FFaceAlpha',1, ...
                        'PLineLocation',    plinelocs,      'MLineLocation',mlinelocs,             'MLineLimit', [80 -80], ... 
                        'MLabelParallel',   mlabpar,        'PLabelMeridian',plabmer, ...              
                        'MeridianLabel','off', 'MLabelLocation',mlabmers, ...  
                        'ParallelLabel','off', 'PLabelLocation',plabpars, ... % label each line?
                        'LabelRotation','on');
                tightmap; % fills axis box; *frame edge is flush with axis edges*
                drawnow;
                if ~isempty(fieldnames(axstruct)); setm(ax, axstruct); end % my override settings
                % Strike #2: Unlike "set", "setm" throws error if you feed it empty structure. Pretty inconsistent, right? Also would take ONE LINE. Mathworks doesn't care.
                    
                %% Make custom lat/lon labels
                % Why do I do this? Strikes #3-5: Matlab doesn't let you place labels outside of frame edge, so for some projections they
                % run up and overlap with edge (#3). If you have color data all inside, much easier to read if you place the labels outside the frame.
                % Matlab horizontal alignment of parallel labels depends on hemisphere/projection (which usually looks funky), and instead of placing meridian 
                % labels at precise map coordinates then setting "cap" or "baseline" alignment so that parallel gridline doesn't cut through text, 
                % Matlab sets "middle" vertical alignment then OFFSETS latitude location (#5). Why? The engineer probably didn't know about text alignment.
                nmlabs = length(mlabmers); nplabs = length(plabpars);
                [xcoords, ycoords] = mfwdtran(repmat(mlabpar,[nmlabs,1]), mlabmers(:));
                for j=1:nmlabs
                    val = lonfix(mlabmers(j)); str = [num2str(val) '^\circ']; % so, can input >180 or <-180
                    if strcmpi(geolab_format,'compass'); if val>0; str = strcat(str,'E'); else; str = strcat(str(2:end),'W'); end; end
                    if nhflag; alignstr = 'top'; elseif shflag; alignstr = 'bottom'; end
                    deg0_rotation_loc = maporig(2); rot = lonfix(val - deg0_rotation_loc); 
                    if shflag; rot = rot*-1; end; if rot<=-90; rot = rot+180; elseif rot>90; rot = rot-180; end
                    text(xcoords(j), ycoords(j), str, 'VerticalAlignment',alignstr, 'HorizontalAlignment','center', 'Rotation',rot, stringset_struct, 'Tag','MLabel');
                end
                [xcoords, ycoords] = mfwdtran(plabpars(:), repmat(plabmer,[nplabs,1]));
                for j=1:nplabs
                    val = plabpars(j); str = [num2str(val) '^\circ'];
                    if strcmpi(geolab_format,'compass'); if val>0; str = strcat(str,'N'); else; str = strcat(str(2:end),'S'); end; end
                    text(xcoords(j), ycoords(j), str, 'VerticalAlignment','middle', 'HorizontalAlignment','center', stringset_struct, 'Tag','PLabel');
                end
            case 'axmflat'
                %% Global projections (update this...)
                latlabs = [ceil(latr(1)/plabsp)*plabsp:plabsp:floor(latr(2)/plabsp)*plabsp]'; 
                lonlabs = [ceil(lonr(1)/mlabsp)*mlabsp:mlabsp:floor(lonr(2)/mlabsp)*mlabsp]'; % need monotonic lon range here!
                mlabpar = min(latr); plabmer = min(lonr);
                axesm('MapProjection','pcarree', ...
                'Frame','on',       'FEdgeColor',edgecolor,     'FFaceColor',oceancolor,'FLineWidth',lwcustom,  'Grid','on', ...
                'MapLatLimit',latr, 'MapLonLimit',lonr, 'MeridianLabel','off', 'ParallelLabel','off',...
                'PLineLocation',latlabs, 'MLineLocation',lonlabs, 'MLabelParallel',mlabpar,'PLabelMeridian',plabmer); % assuming longitude indexed monotonic!!!
                tightmap; % force frame to run up against axes plotbox edges
                drawnow;
                if ~isempty(fieldnames(axstruct)); setm(ax,axstruct); end % my override settings
                %% Custom lat/lon labels
                [xcoords_mer, ycoords_mer] = mfwdtran(repmat(mlabpar,[length(lonlabs) 1]), lonlabs);
                [xcoords_par, ycoords_par] = mfwdtran(latlabs, repmat(plabmer,[length(latlabs) 1]));
                for j=1:length(lonlabs);
                    val = lonfix(lonlabs(j)); str = [num2str(val) '^\circ']; % so, can input >180 or <-180
                    if strcmpi(geolab_format,'compass'); if val>0; str = strcat(str,'E'); else; str = strcat(str(2:end),'W'); end; end
                    text(xcoords_mer(j), ycoords_mer(j), str, 'VerticalAlignment','top', 'HorizontalAlignment','center', 'Tag','MLabel', stringset_struct);
                end
                for j=1:length(latlabs)
                    val = latlabs(j); str = [num2str(val) '^\circ'];
                    if strcmpi(geolab_format,'compass'); if val>0; str = strcat(str,'N'); else; str = strcat(str(2:end),'S'); end; end
                    text(xcoords_par(j), ycoords_par(j), [str ' '], 'VerticalAlignment','middle','HorizontalAlignment','right', 'Tag','PLabel', stringset_struct);
                end
            end
            
            %% Coastline (same method for both)
            % fix holes; want lakes/seas to be "blue" as well
            coast = load('coast.mat'); % matlab's default file
            c=patchm(coast.lat, coast.long, landcolor); 
            xdat = get(c,'XData'); ydat = get(c,'YData'); delete(c); % each column is x/y vertices of individual patch "face"; we separate them
            xs = mat2cell(xdat,size(xdat,1),ones(1,size(xdat,2))); ys = mat2cell(ydat,size(ydat,1),ones(1,size(ydat,2))); % mat2cell(array, rowsplit, columnsplit) -- splits 
                % array into cellarray of submatrices of subsequent lengths specified by rowsplit and columnsplit
            [F, V, xs, ys] = mypoly2fv(xs, ys); 
            % continents, omitting lakes, seas, etc.
            c = patch('Faces',F,'Vertices',V,'FaceAlpha',1,'FaceColor',landcolor, 'Tag','Coast', 'EdgeColor','none'); %%'EdgeAlpha',gridalpha, 'EdgeColor',gridcolor, 'LineStyle','-', 'LineWidth',lwcustom);;
            % coastlines
            c = patchm(coast.lat, coast.long, 'none'); set(c,'EdgeAlpha',1, 'EdgeColor',gridcolor, 'LineStyle','-','LineWidth',lwcustom,'Tag','Coast'); 
            
            %% Custom grid lines (same method for both
            g = hggroup('Tag','Meridians/Parallels','Parent',ax); 
            mlin = findobj(ax,'Type','Line','Tag','Meridian');
            plin = findobj(ax,'Type','Line','Tag','Parallel');
            gridlin = [mlin(:); plin(:)];
            for j=1:length(gridlin) % use patchline to give 
                xdat = get(gridlin(j),'XData'); ydat = get(gridlin(j),'YData');
                delete(gridlin(j));
                patchline(xdat, ydat, 'EdgeAlpha',gridalpha, 'EdgeColor',gridcolor, 'FaceColor','none',...
                    'LineStyle',mapgridstyle, 'LineWidth',lwcustom, 'Parent',g);
            end 
        otherwise
            error('myaxes:Input','Unknown axis type: %s',ax);
        end
        set(ax,'Units',axun); % back to before
    end
    
    %% Output; select axes
    outax = reshape(outax,axsz);
    if ~strcmp(type,'cbar'); 
        axes(axvec(1)); 
    end % select first axes by default

end

