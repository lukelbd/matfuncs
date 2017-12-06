function [ outax ] = myaxsetup( axvec, axtype, varargin )
    % Sets colorbar or plot axes to default properties, or creates 
    % axesm object within given axis. Can change some slightly from
    % default using varargin.
    %
    % Times: For timelabel, instead of inputting date vector, please input the dates/years/months
    % you WANT labeled, along with the d.type of label, and matlab will set the appropriate ticks for that d.type of label.
    % Just include "mon", "daymonthyear", etc. string so that it knows which to pick. timelabel will work by reading
    % the current ticks you set with 'xtick' and 'ytick' (for which you want labels), then apply new ticks with no labels on appropriate locations
    % (e.g. unique days, unque months, etc.), and modify the default datenum label to a date string. Makes sense, because what do I want
    % when I set a time axis? I want to choose ticks/have matlab automatically adjust them, then MODDIFY TICKS and tick labels
    % so they fall on relevant "months", "days", etc. 
    %
    % Note xticklabel and yticklabel won't work here; too ambiguous. Length of get(ax,'xticklabel') can be same as xtick, or same as *visible* xticks
    % and they just weren't reset... in general, confusing. If you need special tick labels that aren't determined automatically, add the functionality
    % here and to myticklabel. Use 'xtime' or 'ytime' for special time labels.

    %% Parse
    [d, setpass, marginpass, tickpass] = myparse('myset', axtype, varargin);
    
    %% Load settings from mymargins
    stringset_struct = mymargins('ax',marginpass);
    edgecolor = stringset_struct.color; 

    %% Loop
    axsz = size(axvec);
    axvec = axvec(:); d.axvec_undercbar = d.axvec_undercbar(:);
    outax = gobjects(1,length(axvec));
    for i=1:length(axvec);
        ax = axvec(i); ax_undercbar = d.axvec_undercbar(i);
        %% Convert ticklength units from pts to (normalized)
        axun = get(ax,'Units'); set(ax,'Units','inches');
        axpos = get(ax,'Position'); maxlen_inches = max(axpos(3:4)); % Matlab sets tick length in normalized units proportional to maximum of (x axis extent, y axis extent)
        ticklen_normal = ticklens(i,:)/maxlen_inches; % normalize the custom "tick length" units set in inches above.
        
        %% Line widths (load from mymargins)
        figh = get(ax,'Parent');
        lwcustom = mymargins('line',figh,marginpass);

        %% REset axis
        resetax(ax);

        %% Set uistack for AXIS at top? sometimes objects can override it, and we never explicitly call uistack

        switch d.type
        %% Axis properties
        case 'ax'
            %% Tick length
            ticklen = ticklens(i,1); %_normal(1)*maxlen_inches; % convert back to scalar unit in inches
            switch d.tickdir
            case {'out','both'}
                switch d.box
                case 'on'; newlen = [axpos(3)-2*ticklen axpos(4)-2*ticklen];
                otherwise; newlen = [axpos(3)-ticklen axpos(4)-ticklen];
                end
                set(ax,'Position',[axpos(1)+ticklen axpos(2)+ticklen newlen]);
            end

            %% Set basic properties
            set(ax,     'Box',          d.box,  ...
                        'Layer',        'top', ... % puts e.g. tick marks on top of objects
                        'TickDir',      d.tickdir, ...
                        'XColor', edgecolor, 'YColor', edgecolor, ... % want to sync edge color with axis text color
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
            if strcmpi(xg,'on')
                set(ax,'XGrid','off');
                xt = get(ax,'XTick');
                g = hggroup('Parent',ax, 'Tag','XGrid');
                for j=1:length(xt)
                    if xt(j)>xl(1) && xt(j)<xl(2)
                        patchline([xt(j) xt(j)],yl,'LineWidth',lwcustom,'LineStyle',d.gridstyle,'EdgeColor',d.gridcolor,'EdgeAlpha',d.gridalpha, ...
                                    'Parent',g);
                    end
                end
            end
            yg = get(ax,'YGrid');
            if strcmpi(yg,'on')
                set(ax,'YGrid','off');
                yt = get(ax,'YTick'); 
                g = hggroup('Parent',ax, 'Tag','YGrid');
                for j=1:length(yt)
                    if yt(j)>yl(1) && yt(j)<yl(2)
                        patchline(xl,[yt(j) yt(j)],'Linewidth',lwcustom,'LineStyle',d.gridstyle,'EdgeColor',d.gridcolor,'EdgeAlpha',d.gridalpha, ...
                            'Parent',g);
                    end
                end
            end
            set(ax,'YLim',yl,'XLim',xl);

            %% My time labels and tick labels
            if d.xtimeflag
                if d.noxticklab; timepass = 'noticklab'; else; timepass = 'yesticklab'; end % if don't want ticks, we just set up special ticks
                mytimelabel(ax, 'x', d.timetype, timepass, marginpass);
            elseif ~d.noxticklab
                set(ax,'XTickLabelMode','auto'); % restore
                if d.xleftmult; multcode = 'xleft'; else; multcode = 'xright'; end
                if d.xlonflag; inp = 'lon'; else; inp = 'normal'; end
                xaxloc = get(ax,'XAxisLocation');
                if strcmpi(xaxloc,'top'); ticktype = 'xtop'; else; ticktype = 'x'; end
                    %ticktype, multcode, d.yesnomult, inp, marginpass
                myticklabel(ax, ticktype, multcode, d.yesnomult, inp, marginpass);
            end
            if d.ytimeflag
                if d.noyticklab; timepass = 'noticklab'; else; timepass = 'yesticklab'; end
                mytimelabel(ax, 'y', d.timetype, timepass, marginpass);
            elseif ~d.noyticklab
                set(ax,'YTickLabelMode','auto'); % restore
                if d.ybottmult; multcode = 'ybott'; else; multcode = 'ytop'; end
                if d.ylonflag; inp = 'lon'; else; inp = 'normal'; end
                yaxloc = get(ax,'YAxisLocation');
                if strcmpi(yaxloc,'right'); ticktype = 'yright'; else; ticktype = 'y'; end
                myticklabel(ax, ticktype, multcode, d.yesnomult, inp, marginpass);
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
        case {'axmnh','axmflat','axmsh'}
            stringset_struct.fontweight = 'bold'; % exception; really hard to see labels in midst of data if not bold
            axes(ax); % Strike #1: For some reason can't use axesm with axis handle input; must be selected beforehand, even though allowing gobject input would 
                % take literally ONE LINE. Matlab is full of surprises.
            set(ax,'Units','inches','Visible','off','TickDir','in'); % for safety, d.tickdir in... not really necessary 
            switch d.type
            case {'axmnh','axmsh'}
                %% Polar azimuthal projections
                axesm('eqdazim', ...
                        'Origin',           d.maporig,        'MapLatLimit',  d.mapbound, ...
                        'Grid',             'on',  ... % they tend to overlap each other on really small subplot if you pick cardinal
                        'Frame',            'on',           'FEdgeColor',   d.edgecolor,      'FLineWidth', d.lwcustom, 'FFaceColor',d.oceancolor, 'FFaceAlpha',1, ...
                        'PLineLocation',    d.plinelocs,      'MLineLocation',d.mlinelocs,             'MLineLimit', [80 -80], ... 
                        'MLabelParallel',   d.mlabpar,        'PLabelMeridian',d.plabmer, ...              
                        'MeridianLabel','off', 'MLabelLocation',d.mlabmers, ...  
                        'ParallelLabel','off', 'PLabelLocation',d.plabpars, ... % label each line?
                        'LabelRotation','on');
                tightmap; % fills axis d.box; *frame edge is flush with axis edges*
                drawnow;
                if ~isempty(fieldnames(axstruct)); setm(ax, axstruct); end % my override settings
                % Strike #2: Unlike "set", "setm" throws error if you feed it empty structure. Pretty inconsistent, right? Also would take ONE LINE. Mathworks doesn't care.
                    
                %% Make custom lat/lon labels
                % Why do I do this? Strikes #3-5: Matlab doesn't let you place labels outside of frame edge, so for some projections they
                % run up and overlap with edge (#3). If you have color data all inside, much easier to read if you place the labels outside the frame.
                % Matlab horizontal alignment of parallel labels depends on hemisphere/projection (which usually looks funky), and instead of placing meridian 
                % labels at precise map coordinates then setting "cap" or "baseline" alignment so that parallel gridline doesn't cut through text, 
                % Matlab sets "middle" vertical alignment then OFFSETS latitude location (#5). Why? The engineer probably didn't know about text alignment.
                nmlabs = length(d.mlabmers); nplabs = length(plabpars);
                [xcoords, ycoords] = mfwdtran(repmat(mlabpar,[nmlabs,1]), d.mlabmers(:));
                for j=1:nmlabs
                    val = lonfix(d.mlabmers(j)); str = [num2str(val) '^\circ']; % so, can input >180 or <-180
                    if strcmpi(d.geolab_format,'compass'); if val>0; str = strcat(str,'E'); else; str = strcat(str(2:end),'W'); end; end
                    if d.nhflag; alignstr = 'top'; elseif d.shflag; alignstr = 'bottom'; end
                    deg0_rotation_loc = maporig(2); rot = lonfix(val - deg0_rotation_loc); 
                    if d.shflag; rot = rot*-1; end; if rot<=-90; rot = rot+180; elseif rot>90; rot = rot-180; end
                    text(xcoords(j), ycoords(j), str, 'VerticalAlignment',alignstr, 'HorizontalAlignment','center', 'Rotation',rot, stringset_struct, 'Tag','MLabel');
                end
                [xcoords, ycoords] = mfwdtran(plabpars(:), repmat(plabmer,[nplabs,1]));
                for j=1:nplabs
                    val = plabpars(j); str = [num2str(val) '^\circ'];
                    if strcmpi(d.geolab_format,'compass'); if val>0; str = strcat(str,'N'); else; str = strcat(str(2:end),'S'); end; end
                    text(xcoords(j), ycoords(j), str, 'VerticalAlignment','middle', 'HorizontalAlignment','center', stringset_struct, 'Tag','PLabel');
                end
            case 'axmflat'
                %% Global projections (update this...)
                latlabs = [ceil(d.latr(1)/d.plabsp)*d.plabsp:d.plabsp:floor(d.latr(2)/d.plabsp)*d.plabsp]'; 
                lonlabs = [ceil(d.lonr(1)/d.mlabsp)*d.mlabsp:d.mlabsp:floor(d.lonr(2)/d.mlabsp)*d.mlabsp]'; % need monotonic lon range here!
                mlabpar = min(d.latr); plabmer = min(d.lonr);
                axesm('MapProjection','pcarree', ...
                'Frame','on',       'FEdgeColor',edgecolor,     'FFaceColor',d.oceancolor,'FLineWidth',lwcustom,  'Grid','on', ...
                'MapLatLimit',d.latr, 'MapLonLimit',d.lonr, 'MeridianLabel','off', 'ParallelLabel','off',...
                'PLineLocation',latlabs, 'MLineLocation',lonlabs, 'MLabelParallel',mlabpar,'PLabelMeridian',plabmer); % assuming longitude indexed monotonic!!!
                tightmap; % force frame to run up against axes plotbox edges
                drawnow;
                if ~isempty(fieldnames(axstruct)); setm(ax,axstruct); end % my override settings
                %% Custom lat/lon labels
                [xcoords_mer, ycoords_mer] = mfwdtran(repmat(mlabpar,[length(lonlabs) 1]), lonlabs);
                [xcoords_par, ycoords_par] = mfwdtran(latlabs, repmat(plabmer,[length(latlabs) 1]));
                for j=1:length(lonlabs);
                    val = lonfix(lonlabs(j)); str = [num2str(val) '^\circ']; % so, can input >180 or <-180
                    if strcmpi(d.geolab_format,'compass'); if val>0; str = strcat(str,'E'); else; str = strcat(str(2:end),'W'); end; end
                    text(xcoords_mer(j), ycoords_mer(j), str, 'VerticalAlignment','top', 'HorizontalAlignment','center', 'Tag','MLabel', stringset_struct);
                end
                for j=1:length(latlabs)
                    val = latlabs(j); str = [num2str(val) '^\circ'];
                    if strcmpi(d.geolab_format,'compass'); if val>0; str = strcat(str,'N'); else; str = strcat(str(2:end),'S'); end; end
                    text(xcoords_par(j), ycoords_par(j), [str ' '], 'VerticalAlignment','middle','HorizontalAlignment','right', 'Tag','PLabel', stringset_struct);
                end
            end
            
            %% Coastline (same method for both)
            % fix holes; want lakes/seas to be "blue" as well
            coast = load('coast.mat'); % matlab's default file
            c=patchm(coast.lat, coast.long, d.landcolor); 
            xdat = get(c,'XData'); ydat = get(c,'YData'); delete(c); % each column is x/y vertices of individual patch "face"; we separate them
            xs = mat2cell(xdat,size(xdat,1),ones(1,size(xdat,2))); ys = mat2cell(ydat,size(ydat,1),ones(1,size(ydat,2))); % mat2cell(array, rowsplit, columnsplit) -- splits 
                % array into cellarray of submatrices of subsequent lengths specified by rowsplit and columnsplit
            [F, V, xs, ys] = mypoly2fv(xs, ys); 
            % continents, omitting lakes, seas, etc.
            c = patch('Faces',F,'Vertices',V,'FaceAlpha',1,'FaceColor',d.landcolor, 'Tag','Coast', 'EdgeColor','none'); %%'EdgeAlpha',d.gridalpha, 'EdgeColor',d.gridcolor, 'LineStyle','-', 'LineWidth',lwcustom);;
            % coastlines
            c = patchm(coast.lat, coast.long, 'none'); set(c,'EdgeAlpha',1, 'EdgeColor',d.gridcolor, 'LineStyle','-','LineWidth',lwcustom,'Tag','Coast'); 
            
            %% Custom grid lines (same method for both
            g = hggroup('Tag','Meridians/Parallels','Parent',ax); 
            mlin = findobj(ax,'Type','Line','Tag','Meridian');
            plin = findobj(ax,'Type','Line','Tag','Parallel');
            gridlin = [mlin(:); plin(:)];
            for j=1:length(gridlin) % use patchline to give 
                xdat = get(gridlin(j),'XData'); ydat = get(gridlin(j),'YData');
                delete(gridlin(j));
                patchline(xdat, ydat, 'EdgeAlpha',d.gridalpha, 'EdgeColor',d.gridcolor, 'FaceColor','none',...
                    'LineStyle',d.mapgridstyle, 'LineWidth',lwcustom, 'Parent',g);
            end 
        otherwise
            error('myaxes:Input','Unknown axis d.type: %s',ax);
        end
        set(ax,'Units',axun); % back to before
    end
    
    %% Output; select axes
    outax = reshape(outax,axsz);
    if ~strcmp(d.type,'cbar'); 
        axes(axvec(1)); 
    end % select first axes by default

function [] = resetax(ax);
        %% Delete all custom stuff
        if 0;textdel = {'XTickLabel','YTickLabel','XTickLabelMultiplier','YTickLabelMultiplier','XLabel','YLabel','MLabel','PLabel'}; 
                % NOTE: WHY DOES IT RESET XLABEL, ETC? Maybe should keep these. Have myset just change reset ticks, etc. In fact
                % I'm pretty sure it SHOULDN'T change axis labels...
        groupdel = {'XGrid','YGrid','Meridians/Parallels','Coast'}; patchdel = {'Coast'};
        for j=1:length(textdel); delete(findobj(ax,'Type','text','Tag',textdel{j})); end
        for j=1:length(groupdel); delete(findobj(ax,'Type','hggroup','Tag',groupdel{j})); end
        for j=1:length(patchdel); delete(findobj(ax,'Type','patch','Tag','Coast')); end
        end

function [] = axadjust(ax, axtype, axpos, ticklen)
    %% Adjust axis position if ticklength is set out or in, so that margin space allocation asumed by myfigure.m is exact and correct.
    % We do this BEFORE setting up text
    case 'cbar'
        switch d.tickdir
        case {'out','both'}
            if hor; newpos = [axpos(1) axpos(2)+ticklen axpos(3) axpos(4)-ticklen]; % label on BOTTOM
            else; newpos = [axpos(1) axpos(2) axpos(3)-ticklen axpos(4)]; % label on RIGHT
            end
            set(ax,'Position',newpos);
        end
    end
    newpos = get(ax,'position'); ticklen_normal = ticklens(i,:)/max(newpos(3:4)); % new tick length
        % NOTE: SHOULD CREATE "MYTICK" FUNCTION THAT SIMPLY DRAWS MY OWN CUSTOM TICKS with SPECIFIED
        % MINORTICK INTERVAL!

