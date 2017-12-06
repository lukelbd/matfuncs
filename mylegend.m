function [ lh ] = mylegend(hpar, hands, labs, varargin)
    % Better legend handling. Simple to use.  
    % Usage:
    %
    % [ lh ] = mylegend(hpar, hands, labs, [(buffer, buffersize), (anchor, anchorloc), (boxswitch)])
    %
    % hands - array or cell-array of graphics object handles. if cell-array, each element of graphic object vector in a cell element will be
    %   plotted sequentially with a single corresponding label (use e.g. for data with patch object for confidence interval). 
    %
    % labs - cell array of strings; the labels (must be same shape as "hands")
    %
    % buffer - scalar buffer, in inches, from anchor location. should be scalar. usage depends on type of legend 
    %   anchor (e.g. if anchor{2}=='ne', buffer adds equal space to right and top)
    %
    % anchor - 2by1/1by2 cell array or numerical array giving legend position and alignment. element 1 corresponds to position on 
    %   axes, and element 2 corresponds to alignment of legend box. can be cardinal directions (e.g. 'n','se','s', etc.) or
    %   numeric (e.g. 0 for north, 2 for east, 5 for southwest, etc.)
    %

    %% Parse input
    loc = {'ne','ne'}; buffer = [.5 .5]; boxoff = false;
    customxspace = false; customyspace = false;
    iarg = 1; 
    while iarg<=length(varargin)
        sw = varargin{iarg}; incr = 2; % default increment
        assert(ischar(sw),'Bad N-V pair inputs.');
        switch lower(sw)
        case 'buffer'
            buffer = varargin{iarg+1};
        case 'anchor'
            loc = varargin{iarg+1};
        case {'xspaces','xspace'}
            assert(isnumeric(varargin{iarg+1})&&numel(varargin{iarg+1})==4,'Bad "XSpaces" input. Must be length 4 vector, with entries [margin, column-space, linelength, line-text space].');
            xspace = varargin{iarg+1}; customxspace = true;
        case {'yspaces','yspace'}
            assert(isnumeric(varargin{iarg+1})&&numel(varargin{iarg+1})==2,'Bad "YSpaces" input. Must be length 2 vector, with entries [margin, row-space].');
            yspace = varargin{iarg+1}; customyspace = true;
        case {'boxoff','nobox','empty'}
            boxoff = true; incr = 1; % a switch
        otherwise; error('Unknown input: %s',sw);
        end
        iarg = iarg+incr;
    end
    % fix hands and legend so that it goes from bottom to top; user input will create "picture" of legend
    hands = flipud(hands);
    labs = flipud(labs);
    
    %% Load settings, defaults
    tp = get(hpar,'Type');
    switch lower(tp)
    case 'axes'
        extraoff = myget(hpar,'Position');
        extraoff = extraoff(1:2);
        figh = get(gca,'Parent');
        figflag = false;
    case 'figure'
        figh = hpar; % alignment and everything is for figure handle
        figflag = true;
        extraoff = [0 0]; % x, y offset if we anchor to axes instead of figure
    otherwise; error('Bad object type. Legend parent must be figure or axis.');
    end
    tx = myget(figh,'DefaultText');
    lset = myget(figh,'LineProperties');
    % default properties to copy into "sample" legend object
    linesetlist = {'LineStyle','Marker','LineWidth','Color','MarkerFaceColor','MarkerEdgeColor','MarkerSize'};
    patchsetlist = {'EdgeColor','FaceColor','EdgeAlpha','FaceAlpha','Marker','LineStyle','MarkerSize','Marker','MarkerFaceColor','MarkerEdgeColor'};
   
    %% Process anchor input
    assert(numel(loc)==2,'Bad anchor input.');
    % translate
    if iscell(loc)
        assert(all(cellfun(@(x)(ischar(x)||isnumeric(x)),loc)),'Bad anchor input.');
        oldloc = loc;
        loc = [0 0]; % pre-allocate (why? so matlab IDE will STFU)
        for jj=1:2
            switch lower(oldloc{jj})
            case 'n';   loc(jj) = 0;
            case 'ne';  loc(jj) = 1;
            case 'e';   loc(jj) = 2;
            case 'se';  loc(jj) = 3;
            case 's';   loc(jj) = 4;
            case 'sw';  loc(jj) = 5;
            case 'w';   loc(jj) = 6;
            case 'nw';  loc(jj) = 7;
            end
        end
    end
    assert(isnumeric(loc),'Bad anchor input');
    assert(all(round(loc)==loc & loc>=0 & loc<=7),'Bad anchor input.');
    % get "edge"
    edge = '';
    switch loc(2)
    case 0; edge = 'North';
    case 2; edge = 'East';
    case 4; edge = 'South';
    case 6; edge = 'West';
    end
    % some combinations aren't allowed; filter these out. We still leave several pretty terrible options...
    % but these are the obviously, always pointless ones.
    if figflag; assert(loc(1)==loc(2),'You specified figure parent with legend child. MUST have anchor e.g. {"n","n"}, {"sw","sw"}, etc.');
    end

    %% Process "label" input
    nlabs = numel(hands); nrow = size(hands,1); ncol = size(hands,2);
    if ~iscell(labs)
        assert(ischar(labs) && size(labs,1)==nlabs,'Bad text label input.');
        oldlabs = labs;
        labs = cell(size(oldlabs,1),1);
        for jj=1:size(oldlabs,1)
            labs{jj} = strtrim(oldlabs(jj,:));
        end
        labs = reshape(labs,[nrow ncol]);
    end
    assert(all(cellfun(@ischar,labs(:))),'Bad text label input.');

    %% Calculate legend box horizontal and vertical extent
    emsquare = tx.FontSize/72;
    % individual LEGEND TEXT ENTRY horizontal/vertical extents
    hexs = zeros(size(labs)); vexs = zeros(size(labs));
    for r=1:nrow; for c=1:ncol;
        th = text(0,0,labs{r,c},tx,'Units','inches','Visible','off'); % tx contains text properties (text currently allows mixes N-V pair and structure input)
%        th = text(0,0,labs{r,c},'Units','inches');
%        set(th,tx);
        ex = get(th,'Extent'); ex = ex(3); % HORIZONTAL extent
        hexs(r,c) = ex(3); vexs(r,c) = ex(4);
        delete(th);
    end; end
    xtext_sp = max(hexs,[],1); % text-xspace, each column
    ytext_sp = max(vexs,[],2); % text-yspace, each row
    % horizontal intermediate spacings
    if ~customxspace;
        xmargin_sp = .75*emsquare; % space between legend box edge and text/graphics objects
        linelen = 4*emsquare; % line-length of REFERENCE line object labeled by text entry
        line_text_sp = .5*emsquare; % space between line and text
        intercol_sp = 1.5*emsquare; % space between column entries
    else % load custom
        xmargin_sp = xspace(1); intercol_sp = xspace(2); linelen = xspace(3); line_text_sp = xspace(4);
    end
    % vertical intermediate spacings
    if ~customyspace; ymargin_sp = .5*emsquare; interrow_sp = 0; % space between top edges and entry
    else; ymargin_sp = yspace(1); interrow_sp = yspace(2);
    end
        % NOTE interrow_sp can be NEGATIVE if the space between "cap"/"top" or "baseline"/"bottom" is too big
    patchheight = emsquare; % won't make this customizeable; would be too confusing maybe... can change though
    % totals
    xlen = 2*xmargin_sp + ncol*(linelen + line_text_sp) + sum(xtext_sp) + (ncol-1)*intercol_sp; %+ ncol*emsquare;
    ylen = sum(ytext_sp) + ymargin_sp*2;
    
    %% Get locations for declaring/drawing text/graphics objects
    % corner locations
    xoffs_line = zeros(1,ncol); xoffs_text = zeros(1,ncol); yoffs = zeros(1,nrow);
    xoffs_line(1) = xmargin_sp; xoffs_text(1) = xoffs_line(1) + linelen + line_text_sp;
    for jj=2:ncol
        xoffs_line(jj) = xoffs_text(jj-1) + xtext_sp(jj-1) + intercol_sp;
        xoffs_text(jj) = xoffs_line(jj) + linelen + line_text_sp;
    end
    yoffs(1) = ymargin_sp + ytext_sp(1)/2; % text/lines will be centered
    for ii=2:nrow
        yoffs(ii) = yoffs(ii-1) + ytext_sp(ii)/2 + interrow_sp;
    end
    % converted to axis units (0-1 in y, 0-1 in x)
    xoffs_line = xoffs_line/xlen; xoffs_text = xoffs_text/xlen; 
    yoffs = yoffs/ylen; % legend "axis" will be from 0 to 1 either direction, so we normalize these
    linelen = linelen/xlen; patchheight = patchheight/ylen; % normalize

    %% Draw legend box; deal with buffer
    pos = myget(hpar,'Position'); 
    anc = zeros(1,2);
    % Position of axis/figure anchor
    switch loc(1) % get position of axis/figure anchor
    case {1,2,3}
        anc(1) = pos(3);
    case {0,4}
        anc(1) = pos(3)/2;
    end
    switch loc(1)
    case {7,0,1}
        anc(2) = pos(4);
    case {6,2}
        anc(2) = pos(4)/2;
    end
    % Lower-left corner of legend starting position
    % Also, interpret *buffer* values
    assert((numel(buffer)==1 || numel(buffer)==2) && isnumeric(buffer),'Bad buffer input. Must be scalar or length 2 numeric vector.');
    if isscalar(buffer); buffer = [buffer buffer]; end
    switch loc(2) % get final position
    case {0,4}
        anc(1) = anc(1)-xlen/2; buffer(1) = 0;
    case {1,2,3}
        anc(1) = anc(1)-xlen; buffer(1) = -buffer(1);
    end
    switch loc(2)
    case {6,2}
        anc(2) = anc(2)-ylen/2; buffer(2) = 0;
    case {7,0,1}
        anc(2) = anc(2)-ylen; buffer(2) = -buffer(2);
    end
    % Apply buffer
    anc = anc + buffer + extraoff;

    %% Create axes, draw lines and write text
    % graphics object can be line or patch. 
    lh=axes('Tag','legend','XLim',[0 1],'YLim',[0 1],'XTick',NaN,'YTick',NaN,'NextPlot','add'); % basic settings; use nextplot add so old graphics objects aren't deleted
    if boxoff % make axis object invisible
        set(lh,'Color','none','XColor','none','YColor','none'); % no box, transparent background.
    else % apply the default settings to match main axes
        set(lh,myget(figh,'AxesProperties')); % includes edgewidth, color, etc. that matches main axes
    end
    % write special properties, and position (recall using "position" with myset means we don't have to worry about units)
    myset(lh,'Bufffer',buffer,'Anchor',anc, ... % legend-specific stuff 
        'Position',[anc xlen ylen],'Parent',hpar,'Edge',edge,'Margin',[0 0 0 0]); % general settings
    % record legend as child in parent object
    myset(hpar,'Children',lh);
    % next
    for r=1:nrow; for c=1:ncol; % remember we flipped handles/labels; r is now going up
        if iscell(hands); objs = hands{r,c}; % multiple objects for one label; e.g. a patch object for margin of error PLUS line/markers
        else; objs = hands(r,c); 
        end
        objs = objs(:); % flatten array of graphics objects
        if isobject(objs) && ~strcmpi(labs{r,c},''); % else leave EMPTY; useful e.g. if we need 2 rows of labels, but have odd number of objects
            for iob=1:length(objs) % sometimes you may want more than 1 object in legend
                % draw
                obj = objs(iob);
                objtype = get(obj,'Type'); 
                switch lower(objtype)
                case 'line'
                    g = get(obj,linesetlist);
                    l = plot(xoffs_line(c)+[0 linelen],[yoffs(r) yoffs(r)]); set(l,linesetlist,g); set(l,'Marker','none'); % Line
                    l = plot(xoffs_line(c)+linelen/2,yoffs(r)); set(l,linesetlist,g); set(l,'LineStyle','none'); % Marker
                case 'patch'
                    g = get(obj,patchsetlist);
                    p = patch('XData',xoffs_line(c)+[0 linelen linelen 0],'YData',[repmat(yoffs(r)-patchheight/2,[1 2]) repmat(yoffs(r)+patchheight/2,[1 2])]); 
                    set(p,patchsetlist,g);
                otherwise; warning('Unknown object type: %s',objtype);
                end
            end
            % write text 
            t = text(xoffs_text(c),yoffs(r),labs{r,c},'HorizontalAlignment','left','VerticalAlignment','center',tx); % takes properties in structure "tx"
%            t = text(xoffs_text(c),yoffs(r),labs{r,c},'HorizontalAlignment','left','VerticalAlignment','center'); 
%            set(t,tx);
        end
    end; end

end
