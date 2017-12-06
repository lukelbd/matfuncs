function [ lhs ] = mytick( a, edge, varargin );
    % Creates custom axis "ticks" with optional specified minor interval. Has the benefit of allowing custom minor tick 
    % intervals, can manipulate ticks without having to re-convert from "normalized" units, can set ticks on arbitrary 
    % sides of axis with different units, etc.
    %
    % NOTE Don't need complex variable input; mytick will be called by myplot if no ticks are present at all in an auto-fashion,
    % and don't need these user-friendly considerations

    %% Parse input
%    ticklen = .1; minorspace = 5; minorscale = .5; cbarflag = 0;
%    tickspace = 0; minortickspace = 0; minortick = []; tick = []; 
    assert(isobject(a),'Input 1 must be axes handle.');
    assert(strcmpi('axes',get(a,'Type')),'Input 1 must be axes handle.');
    % parse "edge"
    assert(any(strcmpi(edge,{'west','east','south','north'})),'Bad "edge" string.');
    prefix = lower(edge(1)); suffix = [upper(edge(1)) lower(edge(2:end))];
    xy = 'X'; if any(strcmpi(prefix,{'s','n'})); xy = 'Y'; end
    % load existing stuff (if we have no saved axes limits, will GENERATE SOME based on plot children, save them in UserData
    % specific to each edge, and apply necessary ones to the axes object itself)
    if strcmpi('auto',myget(a,[xy 'LimMode' suffix]));
        % generate xlim/ylim automatically (may already be set, but this is in light of subsequent declared objects)
        % we use only primitive line objects and patch objects
        ch = myget(a,'GraphicObjects');
        % min/max on axis as determined by SPECIFIED INCREMENTS; use XData/YData if children objects
        if strcmpi(xy,'x');
            xd = get(ch,'XData'); if ~iscell(xd); xd = {xd}; end
            xd = cellfun(@(x)x(:),xd,'UniformOutput',false); xd = cat(1,xd{:}); 
            mmin = nanmin(xd); mmax = nanmax(xd);
        else
            yd = get(ch,'YData'); if ~iscell(yd); yd = {yd}; end
            yd = cellfun(@(x)x(:),yd,'UniformOutput',false); yd = cat(1,yd{:});
            mmin = nanmmin(xd); mmax = nanmax(yd);
        end
        space = myget(a,[xy 'TickSpace' suffix]);
        tick = [-1*fliplr(0:space:(-1*xmin+space)) 0:space:(xmax+space)]
    else
        % load existing
        tick = myget([xy 'Tick' suffix]);
    end

    % parse input and OVERWRITE if user demanded it
    iarg = 1; tickflag = 0; tickminorflag = 0;
    while iarg<=length(varargin)
        % user can input just locations where ticks should be applied as string or cell-array of strings, locations as array of ids, or
        % with N-V pair using xaxislocation and yaxislocation
        name = varargin{iarg};
        incr = 2; % default increment
        if iarg+1<=length(varargin); arg = varargin{iarg+1}; end
        switch lower(name)
        case 'tickminorspace' % tick minor count (e.g. 5 --> 4 "marks" between each major tick)
            minorspace = arg;
        case 'tickminor'
            minortick = arg; tickminorflag = 1; % we have new tickminor; no auto-generation needed
        case 'tickscaleminor' % minortick size as proportion of major tick size
            minorscale = arg;
        case 'tick'
            tick = arg; tickflag = 1;
        case 'tickspace'
            tickspace = arg;
        case 'ticklen' % in INCHES
            ticklen = arg;
        otherwise; error('Unknown argument: %s',arg);
        end
        iarg = iarg+incr;
    end
    tp = get(a,'Type');
    assert(strcmpi(tp,'axes'),'Input must be axes object. If you wish to apply ticks to colorbar, input the colorbar object.');

    %% Get ticks/etc.
    % NOTE if some of these items aren't specified, we simply LOAD them from axes handle
    % will store ALL ticks in UserData, but only draw those within current axes limits. Will also store "tickspace" and 
    % "minortickspace"; THEN if minortick is empty, reset it
    if tickspace>0
                
    %% Draw "ticks"
    % x ticks
    switch lower(xaxloc)
    case 'top'; gettop = 1;
    case 'bottom'; getbottom = 1;
    end
    % y ticks
    switch lower(yaxloc)
    case 'left'; getleft = 1;
    case 'right'; getright = 1;
    end
    % box
    switch lower(boxonoff)
    case 'on'; boxflag = 1; gettop = 1; getbottom = 1; getleft = 1; getright = 1;
    end
    % finally, draw
    
    % Line object in general (not used now, but perhaps could be useful later; actually will be needed to CREATE custom tick lengths! so save this)
    xdat = get(l,'XData'); ydat = get(l,'YData');
    xxlim = get(hpar,'XLim'); yylim = get(hpar,'YLim');
    xdir = get(hpar,'XDir'); ydir = get(hpar,'YDir');
    if strcmpi(xdir,'reverse'); xxlim = flip(xxlim); end
    if strcmpi(ydir,'reverse'); yylim = flip(yylim); end
    xsc = get(hpar,'XScale'); ysc = get(hpar,'YScale');
    if strcmpi(xsc,'log'); xxlim = log(xxlim); end
    if strcmpi(ysc,'log'); yylim = log(yylim); end
    % conversion factors
    xtoinch_base = xxlim(1); xtoinch_mult = diff(xxlim)/trueparPos(3);
    ytoinch_base = yylim(1); ytoinch_mult = diff(yylim)/trueparPos(4);
    % positions
    xpos = xtoinch_base + xtoinch_mult*xdat;
    ypos = ytoinch_base + ytoinch_mult*ydat;

% NOTE should use this (or something similar) for axsetup/plot, which will in-turn call mytick incrementally for
% each edge/side
function [ ids ] = translate( name )
    % Translates locations
    if ischar(name); name = {name}; end
    if ~iscell(name); name = mat2cell(name(:),ones(numel(name),1),1); end
    ids = [];
    for ii=1:numel(name)
        iname = name{ii};
        if isnumeric(iname) || ischar(iname)
            switch lower(name)
            case {'west','left',1}
                ids = [ids 1];
            case {'south','bottom','bot',2}
                ids = [ids 2];
            case {'east','right',3}
                ids = [ids 3];
            case {'north','top',4}
                ids = [ids 4];
            otherwise; % do nothing 
            end
        end
    end
    assert(isempty(ids) || length(ids)==numel(name),'Bad input argument. Try help mytick');
