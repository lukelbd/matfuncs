function [ cbar ] = mycolorbar( hpar, anchor, varargin )
    % Builds custom colorbar using patch objects. Because Matlab restricts user access to the 
    % underlying graphics objects for the sake of stability or user satisfaction, which 
    % ends up doing nothing.
    %
    % Usage: [ cbar ] = mycolorbar( hpar, anchor, [N-V pairs and switches] )
    %
    % "hpar" should have one of 2 formats: 
    %   1) {clim axis reference, alignment reference} OR
    %   2) [reference for both clim and alignment]
    %           -the first option is in case user wants to align w.r.t. the figure, and 
    %            therefore has to specify the axis specifying clim
    % "anchor" can be n, s, e, or w (caps-insensitive)
    % 
    % Optional arguments:
    %   'buffer' - buffer between colorbar and (the [anchor] side of) its alignment reference object, in inches. default is 5pts
    %   'inside'/'in' - place colorbar inside axes object. default for axes is outside, default for figure is inside.
    %   'triangle'/'tri' - give colorbar triangle-shaped ends
    %   'lenscale'/'len' - length RELATIVE to the alignment reference. default 1 for axes, .5 for figure alignment reference.
    %   'width'/'wid' - width of colorbar, in inches. default .2 inches
    %
    % NOTE mycolorbar will NOT auto-update if colormap or color limits are changed.
    % NOTE this will place colorbar beyond any other objects that may be present since myposfix will move other axes around to "make space" for it
    %

    %% Initial stuff
    % get CLim reference axis
    if iscell(hpar)
        climref = hpar{1};
        hpar = hpar{2};
    else; climref = hpar(1);
    end
    % some default settings
    offset = 5/72; width = .2; % try 5-point offset, and .2 inch width
    triflag = false; % has square ends by default
    tp = get(hpar,'Type'); ctp = get(climref,'Type'); if ~iscell(tp); tp = {tp}; end
    % enforce some properties
    switch lower(tp{1})
    case 'axes'; f = get(hpar(1),'Parent'); lenscale = 1; figflag = 0; insideflag = 0; % colorbar ends should align with axes ends, and by default, place colorbar OUTSIDE
    case 'figure'; f = hpar(1); lenscale = .5; figflag = 1; insideflag = 1; % colorbar ends shouldn't be flush against figure end
    otherwise; error('Bad object handle. Use axis or figure.');
    end
    assert(strcmpi(ctp,'axes'),'CLim reference handle must be axes object.')
    assert(numel(anchor)==1 && (isnumeric(anchor) || ischar(anchor)), ...
        'Bad anchor specifier.'); % local "anchor" processing
    anchor = lower(anchor);

    %% Parse input
    for iarg=1:length(varargin);
        arg = varargin{iarg};
        switch lower(arg)
        case 'buffer'
            buffer = varargin{iarg+1}; ndel = 2;
        case {'triangle','tri'}
            triflag = true; ndel = 1; % colorbar with the last level tapering to "triangles"; uses patch
        case {'inside','in'}
            insideflag = true; ndel = 1;
        case {'len','lenscale'} % how long should colorbar be in proportion to reference object length?
            lenscale = varargin{iarg+1}; ndel = 2; 
        case {'width','wid'}
            width = varargin{iarg+1}; ndel = 2;
        otherwise; error('Unknown argument.');
        end
        varargin(iarg:iarg+ndel-1) = []; 
    end
    
    %% For colorbar, we automatically align buffer
    set(hpar,'Units','inches'); parpos = get(hpar,'Position'); if iscell(parpos); parpos = cat(1,parpos); end
    switch anchor
    case {'e',2}
        if insideflag; anchors = {'e','e'}; else; anchors = {'e','w'}; end
        hflag = 0;
        %[~,alignax] = max(parpos(:,1)+parpos(:,3)); % this is how myanchor automatically aligns objects with 2-axis parents
    case {'w',6}
        if insideflag; anchors = {'w','w'}; else; anchors = {'w','e'}; end
        hflag = 0;
        %[~,alignax] = min(parpos(:,1));
    case {'n',0}
        if insideflag; anchors = {'n','n'}; else; anchors = {'n','s'}; end
        hflag = 0;
        %[~,alignax] = max(parpos(:,2)+parpos(:,4));
    case {'s',4}
        if insideflag; anchors = {'s','s'}; else; anchors = {'s','n'}; end
        hflag = 0;
        %[~,alignax] = min(parpos(:,2));
    otherwise; error('Invalid anchor buffer.');
    end
    % alignment properties
    if hflag;
        startlen = [1 width];
        alignkey = 'h';
    else
        startlen = [width 1]; % length will be stretched by myanchor
        alignkey = 'v'; % want vertical stretching
    end
    % get coordinates for colorbar frame patch obect
    minext = (1-lenscale)/2; maxext = 1-(1-lenscale)/2;
    along = [minext maxext maxext minext]; % counter-clockwise, from lower left-hand corner
    across = [0 0 width width]; 
    if hflag; x = along; y = across; else; x = across; y = across; end % counter-clockwise, from lower left-hand corner

    %% Create colorbar
    % each threshold will start 1-point below
    rgb = get(f,'Colormap');
    cbar = axes('Parent',f,'Units','inches','Position',[0 0 startlen],'Visible','off');
    for icol=1:size(rgb,1)
        xlims = [(1-lenscale)/2 1-(1-lenscale)/2
        patch('XData',x,'YData',y,'EdgeColor','none');
    end

    %% Apply ticks when requested

    %% Fix position of other axis objects and current one
    myanchor(cbar, hpar, anchors, buffer, alignkey);
    myposfix(cbar, hpar); % moves other axes out of way; also resets colorbar position

end
