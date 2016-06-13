function [ out ] = mymargins( sw, varargin )  
    % Default Figure/Label/Graphics Object size properties and "margin" sizes;
    % used my myfigure, mytitle, myaxes, myxlabel, myylabel, myticklabel, and mytimelabel.
    % These should be suitable for all publications. Keep in mind
    % appropriation of whitespace around each axes in figure is based on
    % text size. If you change text size, all plot formats must change.
    % Shouldn't be much concern, as we want consistent readability, without
    % unnecessarily letting text take up too much space --> universal,
    % fixed text sizes are appropriate.
    %
    % Why is this its own function? So we don't have to go through each
    % separate "myxlabel, myylabel, etc." and rewrite font size if we
    % decide to change the settings. 
    %
    % Things like margin sizes will be based on tick length (in inches),
    % fontsize, and offset. 
   
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
   
    %% Defaults
    figplacement = '1col'; % defaults
    journ = 'grl';
    
    defcol = [.2 .2 .2]; % default label color. should match "edgecolor" from myaxes. title will be darker.
    defnm = 'Helvetica'; % default label string.  
    defwght = 'normal'; % default font weight
    
    cwidth = 1.65*smallsizenum/72; % colorbar width, in inches. make it twice the label height
    
    ticklen = .35*(smallsizenum/72); % inches
    tick_ticklab_space = .25*smallsizenum/72; % fraction of EM square. convert from points to inches.
    %ticklab_lab_space = .3*bigsizenum/72; % in proportion to bigsizenum; allow stems or subscripts from label to hang down.
    ticklab_lab_space = 0; % then just use bottom align
    %tick_ticklab_space = .3*smallsizenum/72; % fraction of EM square. convert from points to inches.
    %ticklab_lab_space = .35*bigsizenum/72; % in proportion to bigsizenum; allow stems or subscripts from label to hang down.
    ticklab_len_guess = 1.5*smallsizenum/72; % 3 EM squares at most? e.g. 500dam, or 1.23 with multiplier... those are about three
    ticklab_len_guess = 2.5*smallsizenum/72; % 3 EM squares at most? e.g. 500dam, or 1.23 with multiplier... those are about three
    %ticklab_len_guess = 4*smallsizenum/72; % for sensitivity project; had 0.005, e.g.

    tick_timeticklab_space = tick_ticklab_space + .5*(smallsizenum/72)/(1.41); % since it's sideways, need additional space for corner; exactly half the diagonal made by the 45-degree
        % angled right edge of the text. so, hypotenuse equals .5*smallsizenum, then want x-component. 2*a^2=(.5*smallsizenum = .5s)^2=.25s^2 --> a^2=s^2/8 --> a=s/(2sqrt(2))
        % really though, this is a guess. only used by myfigure.m
    timeticklab_len_guess = 2.5*smallsizenum/72; % 5 EM squares? only includes e.g. 2013-Jan-1, etc.
        % ... notice right now these are all identical.
    
    ticklab_height = smallsizenum/72; % 1 EM square.
    lab_height = 1.275*bigsizenum/72; % give some extra space; this is the normal line separation/top-to-bottom extent, no sub/superscripts
    title_height = lab_height;
    %title_height = bigsizenum/72;
    edge_space = .5*bigsizenum/72; % extra separation from figure edge, allowing for label superscripts, etc. plus some spare room

    %title_buffer = .6*bigsizenum/72; % extra space (for aesthetic reasons, should be a bit larger)
    title_buffer = 0;
    
    %twoline_title_space = .2*bigsizenum/72;
    %twoline_title_space = .3*bigsizenum/72; % needed extra space for ^\circ (deg. east, noth, etc.)
    twoline_title_space = 0;
    
    subp_majorsep = .8*smallsizenum/72;
    subp_minorsep = .5*smallsizenum/72;
    subp_majorsep = 1.6*smallsizenum/72;
    subp_minorsep = 1*smallsizenum/72;
    
    switch sw
    %% Figure size settings
    %
    %% Figure width specific to various research journal textwidth/columnwidth/height properties used
    % If you have some latex template for a given journal, write \usepackage{layouts} and \printinunitsof{in}\printlen{[\columnwidth,\textwidth,\textheight]}
    % somewhere in file to get appropriate figure widths for 1col, 2col, and long figures respectively. Then paste numbers in this file MANUALLY. If journal format changes, change this.
    case 'figsize'
        % Movie/online figure?
        if movieflag
            out = 720; %1080 % this is figure height in pixels
            return;
        end
        % Parse and trigger errors
        for j=1:length(varargin)
            arg = varargin{j};
            switch arg
            case {'grl','jc'}
                journ = arg;
            case {'1col','2col','long'}
                figplacement = arg;
            otherwise
                error('Unknown input: %s',arg);
            end
        end
        % Get figure size
        switch journ
        case 'grl'
            switch figplacement
            case '1col'
                out = 3.32153;
            case '2col'
                out = 6.80914;
            case 'long'
                out = 9.42485;
            end
        case 'jc'
            % ... add
        otherwise
            error('Unknown journal specifier: %s.',journ);
        end
    
    %% Internal settings/indep. of figure size (margins, font, labels, objects, titles...)
    %
    %% Objects
    case {'marker','line','hatchline','fatmarker'}
        % Old method looked at figure size max length, but this is silly I think; more consistent to just have all "objects" sizes and separations/margins synced with the fontsize, then with the
        % axes/figure shapes and positions that we want
        switch sw
        case 'marker'
            out = smallsizenum*3/2; % looks nice for "crosses", perhaps points. then it's simple; size of point === line width 
            %out = maxlen*72/marker_fact; % in points; try 1/40th max fig size
        case 'fatmarker' 
            out = smallsizenum; % for squares, circles, diamonds
        case 'line'
            %out = maxlen*72/line_fact;
            %out = smallsizenum*.15;
            out = smallsizenum*.1;%*.15; % should be smaller
        case 'hatchline'
            %out = maxlen*72/hatch_fact;
            out = smallsizenum*.075;
        otherwise
            error('Unknown graphics object identifier: %s',sw);
        end

    %% Font settings (pre-pended to labels, legend, etc.; used by myxlabel, mytitle, ...)
    case {'lab','title','subt','abc','leg','ax'}
        nm = defnm;
        col = defcol;
        wght = defwght;
        switch sw
        case 'lab'
            sz = bigsizenum;
        case {'title','subt'}
            sz = bigsizenum;
            wght = 'bold';
        case 'abc' % e.g. figure a, figure b, ... should probably be bigger than other text.
            sz = abcsizenum;
            wght = 'bold';
        case {'leg','ax'} 
            sz = smallsizenum;
        otherwise
            error('Unknown label type: %s',sw);
        end
        out = struct('fontsize', sz, 'fontweight', wght, 'color', col, 'fontname', nm);
      
    %% Title spacing
    case '2linetitlespace'
        out = twoline_title_space;
    case 'titleoff'
        out = title_buffer;

    %% Tick length
    case 'ticklen'
        out = ticklen;

    %% Tick label Offset
    case {'yticklaboff','yrightticklaboff','xticklaboff','xtopticklaboff','ticklaboff'} % same always
        out = tick_ticklab_space;

    %% Axis tick label multiplier
    case 'multoff' % offset from x, y axis for multiplier
        out = tick_ticklab_space;
    case 'multextend' % extension BEYOND axis edge; we set it the same
        out = tick_ticklab_space;

    %% Label Offset
    case {'xlaboff','ylaboff','laboff'} % offset from MAXIMUM EXTENT of axis tick labels, or from axis itself
        out = ticklab_lab_space;

    %% Margins that "myfigure.m" will use to allocate AXES positions within figure
    case 'cbarwidth'
        out = cwidth;
    case 'bottom'
        time = 0; if ~isempty(varargin); switch varargin{1}; case 'time'; time = 1; end; end
        if time; out = tick_timeticklab_space + timeticklab_len_guess + ticklab_lab_space + lab_height + edge_space;
            % should make allocated space identical, or allow "myfigure" to read the intended xticks, yticks, so that it can 
            % decide on how to allocate space by testing out with  myticklabel and mytimelabel
        else; out = tick_ticklab_space + ticklab_height + ticklab_lab_space + lab_height + edge_space;
        end
    case 'top'
        out = title_buffer + title_height + edge_space;
    case 'bigtop'
        out = title_buffer + 2*title_height + twoline_title_space + edge_space;
    case 'leftnolab'
        out = tick_ticklab_space + ticklab_len_guess + edge_space;
    case 'bottomnolab'
        out = tick_ticklab_space + ticklab_height + edge_space;
    case 'left'
        time = 0; if ~isempty(varargin); switch varargin{1}; case 'time'; time = 1; end; end
        if time; out = tick_timeticklab_space + timeticklab_len_guess + ticklab_lab_space + lab_height + edge_space;
        else; out = tick_ticklab_space + ticklab_len_guess + ticklab_lab_space + lab_height + edge_space;
        end
    case 'right' % a little extra space is better here
        out = 2*edge_space;
    case 'subpbig' % separation between big plots
        out = subp_majorsep;
    case 'subpsmall' % separation between e.g. panels & main plots
        out = subp_minorsep;
    case 'edgespace'
        out = edge_space;
    otherwise
        error('Unknown switch: %s',sw);
    end  
end
