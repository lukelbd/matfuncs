function [ output ] = mytimelabel( ax, xyswitch, varargin )
    % Deals with labelling and *choosing appopriate tick intervals* for axes that represent time. 
    % Needs special considerations for plotting. Places all date labels at "midnight".
    % Input (for setting up axes): 
    % "ax": axis handle.
    % "xyswitch": switch 'x' or 'y'; which axis is for time.
    % "type" (optional): settings for time axis. either of... 
    %           'day' - tick label '01', axis label 'Jan-2013'. if all data falls in same month.
    %           'monthday'  - tick label 'Jan-01', axis label 'year 2013'. if all data falls in same year. DEFAULT OPTION.
    %           'yrsmall' - tick label '01', axis label 'calendar days starting Jan-2013'. if we don't have much space around axis edges.
    %           'yearmonthday' - tick label '2013-01-01', no axis label. 
    %
    % Output:
    % Either output==filestr, a string for naming figure files, or
    % output==lh, the axis label handle.

    %% Set up axis time tick label
    %% Parse input
    varargin = expandcells(varargin); 
    type = 'monthday'; 
    yearflag = false; monthflag = false; nolabflag = false;
    iarg = 1; marginpass = {};
    while iarg<=length(varargin)
        switch lower(varargin{iarg})
        case {'monthday','yearmonthday','day','count','yearmonth'} 
            type = varargin{iarg}; ndel = 1;
        case {'year','month'}
            type = varargin{iarg}; ndel = 1;
        case 'noticklab'
            nolabflag = true; ndel = 1; % just set up appropriate axis ticks
        case 'yesticklab' % for consistency
            ndel = 1;
        case 'figtype'
            marginpass = varargin(iarg:iarg+1); ndel = 2;
        otherwise
            error('Unknown argument: %s',varargin{iarg});
        end
        varargin(iarg:iarg+ndel-1) = [];
    end
    ticksw = [upper(xyswitch) 'Tick']; ticklabsw = [ticksw 'Label']; minorticksw = [upper(xyswitch) 'MinorTick']; % names for N-V pair changes    
    ticksw, ticklabsw, minorticksw

    %% For axis modifications
    set(ax,'Units','inches');
    axpos = get(ax,'Position');
    switch lower(xyswitch)
    case 'x' % time series, usually
        len_along = axpos(3); limi_along = get(ax,'XLim');
        if strcmpi(get(ax,'XDir'),'reverse'); limi_along = flip(limi_along); end
    case 'y' % Hovmoller diagram; should manual set to reverse if desired
        len_along = axpos(4);  limi_along = get(ax,'YLim');
        if strcmpi(get(ax,'YDir'),'reverse'); limi_along = flip(limi_along); end
    end
    inch_to_data_along = diff(limi_along)/len_along; datenumlab = get(ax,ticksw); % should already be custom set. should always be in datenum or year1, year2, ... or month1, month2, ... format
    datenumlab = datenumlab(datenumlab>=min(limi_along) & datenumlab<=max(limi_along)); % must be in axis bounds
    datenumlab_pos_inches = (datenumlab-limi_along(1))/inch_to_data_along; % convert data units to inches
    
    limi_along = sort(limi_along); % now, reorder. inch to data needs correct sign though

    %% Initial settings
    stringset_struct = mymargins('ax',marginpass);

    % Tickdir correction
    ticklen = 0;
    tickdir = get(ax, 'TickDir');
    switch lower(tickdir)
    case {'both','out'}
        ticklen = get(ax, 'TickLen')*max(axpos(3:4)); ticklen = ticklen(1);
    end

    %% Fix tick positions. If ticks too thick w.r.t. axis length, reduce their frequency. But should always fall on meaningful time units.
    % We just enforce ticks on integers. This method is super duper robust and will pretty much never break, no matter how weird your date range is. User
    % just needs to specify (visual inspection) "appropriate" points for ticklabeling using 'XTick' or 'YTick' in myset input.
    tick_interval = 1; 
    ticktest = ceil(limi_along(1)):tick_interval:floor(limi_along(2));
    badticks = true; lw = get(ax,'LineWidth')/72; % line width in inches
    while badticks % enforce aggregate width of tickmarks is no more than one half length of axis in question. otherwise, find integer
        % tick interval that jumps between user-specified tick label positions.
        aggr_tickwidth = numel(badticks)*lw; 
        if aggr_tickwidth<=len_along
            badticks = false;
        else % too close together!
            sp = diff(ticktest); % check that mintick:something:maxtick falls on all ticks, and is integer
            badtickinterval = true; 
            tick_interval = tick_interval+1;
            while badtickinterval
                ticktest = limi_along(1):tick_interval:limi_along(2);
                if all(any(repmat(datenumlab(:),[1 length(ticktest)])==repmat(ticktest(:),[length(datenumlab) 1]),2)); % any along second dimension (enforce each lab falls on ANY of the ticks)
                        % then enforce this happens for ALL label ticks)
                    badtickinterval = false;
                else
                    tick_interval = tick_interval+1;
                end
                if any(tick_interval>=sp); % eventually, will always reach this breakout point
                    badticks = false; badtickinterval = false; % have *only* major ticks on ticklabel locations
                end
            end
        end
    end
    finalticks = ticktest;
    % And setup tick marks
    set(ax, minorticksw, 'off', ... % turn off minor axis ticks (can't control their spacing, and here only certain intervals are meaningful)
            ticksw, finalticks, ... % set up major ticks
            ticklabsw, ''); % empty out ticklabels

    %% If don't want ticklabs, bail.
    if nolabflag;
        output = [];
        return
    end

    %% Set up tick labels, axis labels. 
    switch lower(type)
    % These two require extra margin space
    case 'monthday' % ticks on midnights; datenum input
        timeticklab = datestr(datenumlab, 'dd-mmm');
        dateveclab = datevec(datenumlab);
        timelab = sprintf('from year %d', dateveclab(1,1)); % data is always from single year
        if any(dateveclab(1,1)~=dateveclab(:,1)); warning('Time axis contains dates from different years. Consider "yearmonthday", "count", or "months" format instead.'); end
        rot = 45; xhalign = 'right'; xvalign = 'middle'; yhalign = 'right'; yvalign = 'middle';
    case 'yearmonthday' % ticks on midnights; datenum input
        timeticklab = datestr(datenumlab, 'dd-mmm-yyyy'); % "day" is first, because that is most important information
        timelab = '';
        rot = 45; xhalign = 'right'; xvalign = 'middle'; yhalign = 'right'; yvalign = 'middle';
    % And these two don't. But not especially a big deal if you incude some.
    case {'month','year'}
        if strcmpi(type,'month'); datenumlab = mod(datenumlab-1,12)+1; end % IMPORTANT: for e.g. plotting a few months crossing into new year, have to set up axis with 
                % e.g. 12, 13, 14 for dec, jan, feb.
        timeticklab =  cellstr(num2str(datenumlab(:))); 
        timeticklab = cellfun(@strtrim,timeticklab,'UniformOutput',false);
        timelab = type; % super simple
        rot = 0; xhalign = 'center'; xvalign = 'cap'; yhalign = 'right'; yvalign = 'middle';
    case 'monthname'
        nlab = length(datenumlab);
        timeticklab = cellstr(datestr(datenum([zeros(nlab,1) datenumlab(:) ones(nlab,1) zeros(nlab,3)]),'mmm'));
        timelab = '';
        rot = 45; xhalign = 'right'; xvalign = 'middle'; yhalign = 'right'; yvalign = 'middle';
    case 'count' % ticks on integers
        basetime = datenumlab(1); % start from a midnight, ideally
        timeticklab = num2str(datenumlab(:) - basetime);
        timelab = sprintf('days from %s', datestr(basetime, 'dd-mmm-yyyy')); % if 'monthday' causes overlapping ticklabels
        rot = 0; xhalign = 'center'; xvalign = 'cap'; yhalign = 'right'; yvalign = 'middle';
    end

    %% Apply tick labels at points of original ticks
    %tickoffset = mymargins('timeticklaboff',varargin); % inches from edge
    tickoffset = mymargins([lower(xyswitch) 'ticklaboff'],varargin); % should delete "time offset" properties from that function... though they are still used myfigure.m; not surea
        % also, should we allow custom timelab tick rotation? maybe just decide on something? could be steeper than 45
    noff = -tickoffset-ticklen; % convert inches to data units 
    g = hggroup('Parent',ax, 'Tag',[upper(xyswitch) 'TickLabel']);
    for it=1:length(datenumlab)
        switch lower(xyswitch)
        case 'x'
            extraoffset = .5*abs(sin(rot*pi/180))*stringset_struct.fontsize/72; % since the little corner might overlap the axis edge; we put it really close.
                % required because rotation pivots on right at middle-height point
            t=text(datenumlab_pos_inches(it), noff + extraoffset, timeticklab(it,:), ...
                'Parent', g, ...
                'HorizontalAlignment',xhalign, ...
                'VerticalAlignment',xvalign, ...
                'Rotation',rot, ...
                'Tag', 'XTickLabel', ...
                'Units','inches', ...
                stringset_struct);
        case 'y'
            % extraoffset = .5*abs(cos(rot*pi/180))*stringset_struct.fontsize/72; % 
            t=text(noff, datenumlab_pos_inches(it), timeticklab(it,:), ... % here don't need extra offset; text is cap aligned, and rotation pivots on top-right corner
                'Parent', g, ...
                'HorizontalAlignment',yhalign, ...
                'VerticalAlignment',yvalign, ...
                'Rotation',rot, ...
                'Tag', 'YTickLabel', ...
                'Units','inches', ...
                stringset_struct);
        end
        set(t,'Units','data');
    end

    %% Apply label
    switch xyswitch
    case 'x'
        lh = myxlabel(ax, timelab, marginpass);
    case 'y'
        lh = myylabel(ax, timelab, marginpass);
    end

    %% Output
    output = {lh,g}; % axis labels... but you shouldn't need to manipulate them.
        % output is optional.
 
end
