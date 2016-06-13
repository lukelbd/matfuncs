function [ lh ] = mylegend(ax, hands, labs, varargin)
    % Better legend handling. Simple to use.  
    % Usage:
    %
    % [ lh ] = mylegend(ax, hands, labs, [(buffer, buffersize), (anchor, anchorloc), (boxswitch)])
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
    iarg = 1; loc = {'ne','ne'}; buffer = [.5 .5]; boxoff = false;
    while iarg<=length(varargin)
        sw = varargin{iarg}; flag = true;
        switch lower(sw)
        case 'buffer'
            buffer = varargin{iarg+1};
            ndel = 2;
        case 'anchor'
            loc = varargin{iarg+1};
            ndel = 2;
        case 'boxoff'
            boxoff = true;
            ndel = 1;
        otherwise
            flag = false;
        end
        if flag;
            varargin(iarg:iarg+ndel-1) = [];
        else
            iarg = iarg+1; % and pass that argument to mymargins
        end
    end
    if buffer<0; error('Buffer must be positive scalar or 1by2/2by1 vector.'); end
    if isscalar(buffer); buffer = [buffer buffer]; end
    
    %% Load settings, defaults
    extraoff = [0 0]; % x, y offset if we anchor to axes instead of figure
    tp = get(ax,'Type');
    set(ax,'Units','inches'); % default
    if strcmp(tp,'axes')
        extraoff = get(ax,'Position');
        extraoff = extraoff(1:2);
        figh = get(gca,'Parent');
        axflag = true;
    else
        figh = ax;
        axflag = true;
    end
    set(figh,'Units','inches');
    tx = mymargins('leg',varargin); % legend text propreties; get length of longest string
    lwcustom = mymargins('line',figh,varargin); 
    linesetlist = {'LineStyle','Marker','LineWidth','Color','MarkerFaceColor','MarkerEdgeColor','MarkerSize'};
    patchsetlist = {'EdgeColor','FaceColor','EdgeAlpha','FaceAlpha','Marker','LineStyle','MarkerSize','Marker','MarkerFaceColor','MarkerEdgeColor'};
    
    %% Get anchor location
    if iscell(loc)
        oldloc = loc;
        loc = [0 0];
        for j=1:2
            switch lower(oldloc{j})
            case 'n';   loc(j) = 0;
            case 'ne';  loc(j) = 1;
            case 'e';   loc(j) = 2;
            case 'se';  loc(j) = 3;
            case 's';   loc(j) = 4;
            case 'sw';  loc(j) = 5;
            case 'w';   loc(j) = 6;
            case 'nw';  loc(j) = 7;
            end
        end
    end
    
    %% Can be cell array of string or regular array
    if ~iscell(labs)
        oldlabs = labs;
        labs = cell(size(oldlabs,1),1);
        for j=1:size(oldlabs,1)
            labs{j} = strtrim(oldlabs(j,:));
        end
    end
    nlabs = numel(labs); nrow = size(labs,1); ncol = size(labs,2);
    
    %% Calculate legend box extent
    exs = zeros(size(labs));
    for r=1:nrow; for c=1:ncol;
        th = text(0,0,labs{r,c},tx,'Units','inches'); % tx contains text properties
        %get(th)
        ex = get(th,'Extent'); ex = ex(3);
        exs(r,c) = ex;
        delete(th);
    end; end
    emsquare = tx.fontsize/72;
    xtext_sp = max(exs,[],1); % try this: EM -- EM label EM, where each is em square
    ytext_sp = 1.4*emsquare; % extra space either side
    linelen = 4*emsquare;
    xmargin_sp = .75*emsquare; % extra space
    ymargin_sp = .5*emsquare;
    line_text_sp = .5*emsquare;
    intercol_sp = 1.5*emsquare;
    
    xlen = 2*xmargin_sp + ncol*(linelen + line_text_sp) + sum(xtext_sp,2) + (ncol-1)*intercol_sp; %+ ncol*emsquare;
    ylen = ytext_sp*nrow + ymargin_sp*2;
    
    xoffs_line = zeros(1,ncol); xoffs_text = zeros(1,ncol);
    xoffs_line(1) = xmargin_sp; xoffs_text(1) = xoffs_line(1) + linelen + line_text_sp;
    for j=2:ncol
        xoffs_line(j) = xoffs_text(j-1) + xtext_sp(j-1) + intercol_sp;
        xoffs_text(j) = xoffs_line(j) + linelen + line_text_sp;
    end
    yoffs = ymargin_sp + ytext_sp/2 + (0:nrow-1)*ytext_sp;
    
    xoffs_line = xoffs_line/xlen; xoffs_text = xoffs_text/xlen; 
    yoffs = yoffs/ylen; % legend "axis" will be from 0 to 1 either direction, so we normalize these
    linelen = linelen/xlen; emsquare = emsquare/ylen; % normalize
    
    %% Draw legend box
    pos = get(ax,'Position'); 
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
    %if axflag; anc(1:2) = anc(1:2) + extraoff; end
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
    %anc, xlen, ylen, lwcustom
    lh=axes('Units','inches','Position',[anc xlen ylen],'TickLen',[0 0],'Box','on', 'Tag','legend',...
        'LineWidth',lwcustom,'XColor',tx.color,'YColor',tx.color,'XLim',[0 1],'YLim',[0 1],'XTickLabel','','YTickLabel',''); % colors should match
    if boxoff; set(lh,'Color','none','XColor','none','YColor','none'); end % no box, transparent background.
    hold on;
    for r=1:nrow; for c=1:ncol;
        disprow = nrow-r+1;
        if ~strcmp(labs{r,c},'')
            if iscell(hands); objs = hands{r,c}; % multiple objects for one label; e.g. a patch object for margin of error PLUS line/markers
            else; objs = hands(r,c); 
            end
            objs = objs(:); % flatten array of graphics objects
            for iob=1:length(objs) % sometimes you may want more than 1 object in legend
                obj = objs(iob);
                objtype = get(obj,'Type'); 
                switch lower(objtype)
                case 'line'
                    g = get(obj,linesetlist);
                    l = plot(xoffs_line(c)+[0 linelen],[yoffs(disprow) yoffs(disprow)]); set(l,linesetlist,g); set(l,'Marker','none'); % Line
                    l = plot(xoffs_line(c)+linelen/2,yoffs(disprow)); set(l,linesetlist,g); set(l,'LineStyle','none'); % Marker
                case 'patch'
                    g = get(obj,patchsetlist);
                    p = patch('XData',xoffs_line(c)+[0 linelen linelen 0],'YData',[repmat(yoffs(disprow)-emsquare/2,[1 2]) repmat(yoffs(disprow)+emsquare/2,[1 2])]); 
                    set(p,patchsetlist,g);
                end
                if iob==1;
                    tx.fontweight = 'bold';
                    t = text(xoffs_text(c),yoffs(disprow)-emsquare/3,labs{r,c},'HorizontalAlignment','left','VerticalAlignment','baseline',tx);
                end
            end
        end
    end; end

end
