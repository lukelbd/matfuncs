function [ output ] = myticklabel( ax, xyswitch, varargin );
    % Custom xtick/ytick label, with fixed spacing from margins. Compatible with
    % the rest of my "custom plotting suite."
    %
    % Required input: myticklabel( ax, xysw ) where xysw is 'x' or 'y'
    % (which axis are we talking about?).
    %
    % Note 'xtick' and 'ytick', if you want custom values, will be set up by myset
    % before this function is reached if you invoked myset(...,'x/ytick',x/ytickarrays).
    %
    % Optional input: 
    %   'nomult' - force no multiplier; write numbers in long form (no sci. notation).
    %   'ybott' - place yticklabel multiplier on bottom, instead of top
    %   'xleft' - place xticklabel multiplier on left, instead of right
    %   nsigfig - number of digits for labels (NOT DONE YET - COMING SOON?)
    %
    %   Matlab seems pretty good at automatically selecting labels/multipliers.
    %   Only case I've run into is when I want the whole value printed,
    %   e.g. 500dam, rather than 5. with x10^2 multiplier, which is why
    %   I've enabled the 'nomult' option.
    

    %% Switches default
    expandticks_flag = 0;
    sigflag = 0;
    xleftmult = false; ybottmult = false; lonflag = false; marginpass = {};
    % ytickfudge = mymargins('yticklabfudge'); % "top" of numbers if not really top; there is space there, so doing center
        % vertical alignment will leave some offset. add fudge factor.
    
    %% Parse input
    varargin = expandcells(varargin); % expand out cell arrays
    if ~isempty(varargin)
        iarg = 1;
        while iarg<=length(varargin)
            flag = true;
            arg = varargin{iarg};
            if isscalar(arg) && isnumeric(arg) % sigfig
                nsigfig = arg;
                sigflag = 1; ndel = 1;
            elseif isnumeric(arg) % these are the custom ticks.
                tick = arg;
                customtick = 1; ndel = 1;
            else
                switch arg
                case 'nomult' % if data large/small, do not use multiplier. write it out.
                    expandticks_flag = 1; ndel = 1;
                case 'yesmult'; ndel = 1; % for consistency
                case 'xleft' % mult on left
                    xleftmult = true; ndel = 1;
                case 'xright'; ndel = 1; % mult on right; this is default. included for consistency
                case 'ybott' % mult on bottom
                    ybottmult = true; ndel = 1;
                case 'ytop'; ndel = 1; % mult on top; this is default. included for consistency
                case 'lon';
                    lonflag = 1;
                case 'normal'; ndel = 1;
                case 'figstyle'
                    marginpass = varargin(iarg:iarg+1); ndel = 2;
                otherwise
                    error('Unknown argument: %s',arg);
                end
            end
            varargin(iarg:iarg+ndel-1) = [];
        end
    end
    
    %% Axis modifications
    set(ax,'Units','inches');
    axpos = get(ax,'Position'); 
    xdir = get(ax,'XDir'); ydir = get(ax,'YDir');
    xflag = false;
    switch lower(xyswitch)
    case {'xtop','x'}
        xflag = true;
        alongdir = get(ax,'XDir'); 
        tcode = 'XTick';
        tlcode = 'XTickLabel'; scalecode = 'XScale';
        limi_along = get(ax,'XLim'); 
        along_inchpos_end = axpos(3); across_inchpos_end = axpos(4);
    case {'yright','y'}
        alongdir = get(ax,'YDir'); 
        tcode = 'YTick';
        tlcode = 'YTickLabel'; scalecode = 'YScale';
        limi_along = get(ax,'YLim'); 
        along_inchpos_end = axpos(4); across_inchpos_end = axpos(3);
    end

    %% Get ticks
    tick = get(ax,tcode); 

    %% Fix ticks; if user included xtick, ytick, xticklabel, or yticklabel in myset.m, they will already be applied. otherwise, this draws up the defaults.
    tick = tick(tick>=limi_along(1) & tick<=limi_along(2)); % otherwise length(tick)~=length(ticklab) necessarily, 
        % since you can specify "xtick" but Matlab only places labels if it is withint the Xlim/Ylim of the axes
    set(ax,[tlcode 'Mode'],'auto'); set(ax,tcode,tick); % resets any user-changed ticklabels, and make sure all labels are within axis bounds
    ticklab = get(ax,tlcode); % get auto-generated tick labels

    %% If "out"/"both" ticks are present, extent position by default ticklength
    acrosstick = get(ax,'TickDir');
    switch lower(acrosstick)
    case {'both','out'}
        addspace = get(ax,'TickLen')*max(axpos(3:4)); addspace = addspace(1); % mymargins provides values in INCHES
    otherwise
        addspace = 0;
    end
    negflag = false; % change "inch_to_data_along" sign, when we determine it?
    switch lower(alongdir) % fix limit start
    case 'reverse'
        limi_bottom = limi_along(2); negflag = true; 
    otherwise
        limi_bottom = limi_along(1);
    end
    
    %% Multiplier
    % Detect matlab's intended multiplier from the automatically generated axis tick labels.
    tno0 = tick(tick~=0); tlno0 = ticklab(tick~=0);
    if isempty(tlno0); mult = 0; else; mult = round(log10(tno0(1)/str2double(tlno0{1}))); end % ROUND seems sketchy, but probably safe. e.g. if label value is 1.23 and actual value 1.23456*10^8, will get .9..stuff..*10^8 
        % on division which will give 7.999... as a log10, witch returns "8". don't think this will ever give wrong numbers.
        % note if the only tick is "zero", will be empty (which you probably didn't want; though this way, at least it won't trigger error).
    if expandticks_flag
        multlab == ''; 
        ticklab = cellstr(num2str([tick(:)],'%.f')); % assume integers in this case
    elseif mult==0 % data is already small enough
        multlab = '';
    else
        multlab = ['\times10^{' sprintf('%.f',mult) '}']; % note you can't put TeX markup
            % as an sprintf argument; it deletes backslashes (assumes a special command will follow).
    end 
    if lonflag
        ticklab = cellstr(num2str([lonfix(tick(:))],'%.f'));
    end

    %% Log scale??? and FINAL TICK LOCATIONS
    if strcmpi(get(ax,scalecode),'log')
        limi_along = log10(limi_along); 
        limi_bottom = log10(limi_bottom);
        tick = log10(tick); 
    end
    inch_to_data_along = (limi_along(2)-limi_along(1))/along_inchpos_end;
    if negflag; inch_to_data_along = inch_to_data_along*-1; end
    loc_along = (tick-limi_bottom)/inch_to_data_along; % NO ADDSPACE, because we set text in data units below.
        % when figure repositioned, text follows ALONG axis. ALSO, if direction is negative, gets converted to minus 1
        % what if log units? then distance from lowest value is (log10) that

    %% Write labels
    % Offsets (ticklab and mult should be identical... can delete that option from mymargins soon)
    toff = -1*(mymargins([xyswitch 'ticklaboff'],marginpass)+addspace);
    toff_right = -1*toff+across_inchpos_end; toff_top = -1*toff+across_inchpos_end;
    moff = -1*(mymargins('multoff',marginpass)+addspace);
    moff_right = -1*moff+across_inchpos_end; moff_top = -1*moff+across_inchpos_end;
    % Multiplier settings
    multextend = mymargins('multextend',marginpass);
    if xleftmult || ybottmult;
        malign = -multextend; % multiplier below the axis minimum
    else
        malign = along_inchpos_end + multextend; % multiplier above axis
    end
    if xleftmult; halign_mult = 'right'; else; halign_mult = 'left'; end % alignments
    if ybottmult; valign_mult = 'cap'; else; valign_mult = 'baseline'; end

    g = hggroup('Parent',ax, 'Tag',tlcode); % "Tag" it with xticklabel/yticklabel %[upper(xyswitch(1)) 'TickLabel']);
    stringset_struct = mymargins('ax',marginpass); % with font settings

    for it=1:length(ticklab)
        m = 0;
        switch xyswitch
        case 'xtop'
            t=text(loc_along(it), toff_top, ticklab{it}, ...
                'Parent', g, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','baseline', ...
                'Units', 'inches', ...
                stringset_struct);
            if it==length(ticklab)
                m = text(malign, moff_top, multlab, ...
                'Parent', ax, ...
                'HorizontalAlignment',halign_mult, ...
                'VerticalAlignment','baseline', ...
                'Tag','XTickLabelMultiplier', ...
                'Units', 'inches', ...
                stringset_struct);
            end
        case 'x'
            t=text(loc_along(it), toff, ticklab{it}, ...
                'Parent', g, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','cap', ...
                'Units', 'inches', ...
                stringset_struct);
            if it==length(ticklab)
                m = text(malign, moff, multlab, ...
                'Parent', ax, ...
                'HorizontalAlignment',halign_mult, ...
                'VerticalAlignment','cap', ...
                'Tag','XTickLabelMultiplier', ...
                'Units', 'inches', ...
                stringset_struct);
            end
        case 'y'
            %text(toff, loc_along(it)+ytickfudge*inch_to_data_along, [axprefix ticklab{it}], ...
                t=text(toff, loc_along(it), ticklab{it}, ... 
                'Parent', g, ...
                'HorizontalAlignment','right', ...
                'VerticalAlignment','middle', ...
                'Units','inches', ...
                stringset_struct);
            if it==length(ticklab)
                m = text(moff, malign, multlab, ...
                'Parent', ax, ...
                'HorizontalAlignment','right', ...
                'VerticalAlignment',valign_mult, ...
                'Tag','YTickLabelMultiplier', ...
                'Units', 'inches', ...
                stringset_struct);
            end
        case 'yright'
            %text(toff_right, loc_along(it)+ytickfudge*inch_to_data_along, [axprefix ticklab{it}], ...
                t=text(toff_right, loc_along(it), ticklab{it}, ...
                'Parent', g, ...
                'HorizontalAlignment','left', ...
                'VerticalAlignment','middle', ...
                'Units', 'inches', ...
                stringset_struct);
            if it==length(ticklab)
                m = text(moff_right, malign, multlab, ...
                'Parent', ax, ...
                'HorizontalAlignment','left', ...
                'VerticalAlignment',valign_mult, ...
                'Tag','YTickLabelMultiplier', ...
                'Units', 'inches', ...
                stringset_struct);
            end
        end
        %if m~=0; set(m,'Units','inches'); end; set(t,'Units','inches');
    end
    set(ax,tlcode,''); % turn off background tick labels; we just made our own!
    
    %% Output
    output = {g, m}; % just handles for text objects
    
end
