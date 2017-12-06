function [ varargout ] = setup( varargin )
    % My function for setting custom figure sizes (in inches) and axes positions within the figure.
    % WARNING/NOTE: If total figure size too small and using XMing on Windows, window will be forcibly resized! Haven't tried yet on
    % just Windows, but could also be the case there... actually it seems that DEFINITELY IS THE CASE; need to force Windows to not 
    % impose minimum figure sizes
    %
    % Usage: [f, axharray] = myfigure( [subpArray], N-V pairs )
    %
    % NOTE1 figure-type profiles: <journalnamecode> for journals (USER SHOULD ADD TO RELEVANT BLOCK) and 'movie'/'video' for movie
    % NOTE2 string profiles: 't','s','m','l'/'b','h' (tiny/small/medium/large-big/huge)
    % NOTE3 all switches/names are case insensitive
    %
    % subpArray format:
    %       2-d array of integers, numbered sequentially from 1 to NAxes; equivalent integers must form 
    %       rectangles/squares; the array makes a "picture" of the rudimentary subplot arrangement
    %
    % N-V pairs:
    % 
    %   {'Template',figtype} -- Template for figure width/size restrictions.
    %       figtype OPTIONS:            s (string template) or {s1,s2} (s1 is journal name, s2 is additional specifier, like "1-column")
    %
    %   {'UnitWidth',unitWidth}
    %   {'UnitHeight',unitHeight}
    %   {'Unit'} -- Unit width/height for building subplot arrays (use UNIT for scalar or 2d input); each block/number in array will be this width/height, or changed by row/colratios/aspectratios
    %       unitWidth/height OPTIONS:   s (string profile) or n (number, inches) for width/height
    %       NOTE 'Unit' option is just for convenience
    %
    %   {'Width',width}
    %   {'Height',height}
    %   {'Size',size} -- Fixed figure width/height in inches; will turn on height-fixing if enabled. if 0, means width/height are NOT fixed
    %       NOTE 'Size' option is just for convenience
    %
    %   {'FontSize',fontsizes} -- Fontsizes for 3 classes: axes, label, and ABC/numbering tag
    %
    %   {'rowARR',rowAR}
    %   {'colARR',colAR} -- Aspect ratios to apply to each row/column in subplot array
    %       rowAR/colAR OPTIONS:          [n1,...,nN] (numbers) or {s1,s2,...,sN} (number/string mix) normal or cell vector
    %                                       where N is number of rows/columns.
    %                                   n (number) or s (string) if the aspect ratio is same for all rows/columns
    %   {'rowRatio',rowRatio}
    %   {'colRatio',colRatio} -- RELATIVE respective column widths/row widths
    %       rowRatio/colRatio OPTIONS:          [n1,...,nN] where N is number of rows/columns. 
    %
    % NOTE4 if both rowAR and rowRatio are used, their effects are compounded; should generally use JUST ONE
    % NOTE5 if template with fixed width/height is specified, unitWidth/unitHeight are ignored and the profile width/height used
    % NOTE6 if not speciifed, then either
    %   a) the row/column-ratio inputs will be scaled such that their TOTAL WIDTH/HEIGHT equal unitWidth*ncols and unitHeight*nrows
    %       * allow TWO ratio inputs
    %   b) the row/column-AR inputs will be scaled in the same way; e.g. for ColAR input of [1 .5 1], the total width will be unitWidth*3
    %       but the total height will be DEPENDENT on the implied total AR (i.e. AR of row is then reciprocal of added reciporcals (y1/x1 y2/x2 y3/x3 and want
    %       scale all y's to "1" by getting reciprocal decimal, then x/y of row is (x1+x2+x3)/y and AR is inverse, so HEIGHT is unitWidth*ncols*AR
    %       * allow ONLY ONE AR input (row- or column-AR)
    %
    %   {'rowMargin',rowMargin}
    %   {'colMargin',colMargin} -- Row/column margins in-between subplot array
    %       rowMargin/colMargin OPTIONS:          [n1,...,nN] (numbers) or {s1,s2,...,sN} (number/string mix) normal or cell vector
    %                                       where N is number of rows/columns.
    %                                   n (number) or s (string) if the margin width is same between all rows/columns
    %
    % Switches:
    %   'HoldAR' -- If passed, fixes aspect ratio?
    %   'FixStretch' -- If passed, when e.g. vertical margin INTERSECTING another axes is widened, we fix the rows having axes that had to be stretched.
    %                Automatically enables "HoldAR" when turned on
    %
%% OLD:
%%    %   {'HoldAR','on'/'off'} -- Fix aspect ratio?
%%    %   {'FixStretch','on'/'off'} -- If a vertical margin INTERSECTING another axes is stretched, do we fix the rows having axes spanning that gap that
%%    %                                           had to be stretched?

%----------------------------------------------------------------------------------------------------
% Initial stuff (defaults, load N-V pairs)
%----------------------------------------------------------------------------------------------------
    %% Screen size
    set(0,'Units','pixels'); sz1 = get(0,'screensize'); set(0,'Units','inches'); sz2 = get(0,'screensize');
    res = sz1(3)/sz2(3); % pixels/inches; will always match sz1(4)/sz2(4)... pixels are not rectangular
    pix_to_pt = 72*(1/res); % graphics objects always have size set in "points"; only font can be set with pixels
    pix_to_in = (1/res); % multiply by this to go from pixels to inches
    in_to_pix = res; % multiply by this to go from inches to pixels
    %fprintf('Screen resolution: %ddpi X, %ddpi Y\n', xres, yres);

    %% Defaults
    writeflag = true;
    % margins, aspect ratios, unit widths/heights, subplots
    rowMargin = 'm'; colMargin = 's';
    unitWidth = 'm'; unitHeight = 'm';
    rowAR = []; colAR = []; % "0" means we ignore these
    rowRatio = 1; colRatio = 1;
    subpArray = 1;
    HoldAR = false; fixStretch = false;
    units = 'inches';
    % colors for all "background" objects: labels, axis boxes, ticks, etc.
    figureColor = [.2 .2 .2];
    % text weights, sizes
    fontnm = 'Helvetica'; % Sans-Serif better for plots; don't use the font defaulted with LaTeX interpreter
    fontweight = 'normal';
    titlefontweight = 'bold'; % for title, suptitle, etc.
    fontsize = [7.5 8 10]; % ax, lab, abc
    fontunits = 'points';
    % figure FIXED dimensions default
    width = 0; height = 0; % will be filled in if necessary
    template = ''; primary = '';
    secondary = '2col'; % e.g. if user says "GRL" format but does not specify location, use 2-column limit
        % NOTE generally we just limit a plot for journals by its smallest dimension; don't worry about e.g. if it is taller than leter page
    dpi = 300; % PNG-version, just save at 300dpi

    %% Parse input
    % load subplot array (first, optional argument [implicit, since it should be VERY commonly used])
    singleAxis = 1; % default is user supplies no subplot array (i.e. figure has single axis)
    if ~isempty(varargin); if ~ischar(varargin{1}); singleAxis = 0; end; end
    if singleAxis; subpArray = 1;
    else; subpArray = varargin{1}; varargin = varargin(2:end);
    end
    % initial flags, etc.
    assert(mod(length(varargin),2)==0,'Input must be name-value pairs.');
    aColFlag = 0; aRowFlag = 0; templateFlag = 0; ratioFlag = 0; lenFlag = 0; 
    inWidth = 0; inHeight = 0; inunitWidth = 0; inunitHeight = 0;
    figsizeFlag = 0; unitFlag = 0;
    % load stuff
    iarg = 1;
    stretchnms = {'fixstretch','fixedstretch','stretchfix','stretchfixed'}; % because I will always forget
    arnms = {'arfixed','fixar','fixedar','arfix','arhold','holdar'};
    while iarg<=length(varargin)
        incr = 2; % DEFAULT increment (N-V pairs)
        name = varargin{iarg};
        if any(strcmpi(name,[arnms stretchnms]));
            %% SWITCHES (not paired; increment down varargin is 1)
            switch lower(name)
            case arnms; HoldAR = true; incr = 1;
            case stretchnms; fixStretch = true; incr = 1;
            end
            % NOTE fixstretch works on the axes in an entire row/column; so if you want to preserve an AXES aspect ratio, it must
                % occupy the ENTIRE row/column itself
        else
            %% N-V pairs
            val = varargin{iarg+1};
            switch lower(name)
            % Templates
            case 'template'; template = val; templateFlag = 1;
            % Unit widths
            case 'unitwidth'; unitWidth = val;
            case 'unitheight'; unitHeight = val;
            case 'unit'; unit = val; unitFlag = 1;
            % Widths/heights
            case 'width'; width = val; lenFlag = 1;
            case 'height'; height = val; lenFlag = 1;
            case 'size'; figsize = val; lenFlag = 1; figsizeFlag = 1;
            % Row/column ratios
            case 'rowratio'; rowRatio = val; ratioFlag = 1;
            case 'colratio'; colRatio = val; ratioFlag = 1;
            % Aspect Ratios
            case 'rowar'; rowAR = val; aRowFlag = 1;
            case 'colar'; colAR = val; aColFlag = 1;
            % Margins
            case 'rowmargin'; rowMargin = val;
            case 'colmargin'; colMargin = val;
            case 'margin'; rowMargin = val; colMargin = val;
            % input units
            case 'units'; units = val;
            case 'fontunits'; fontunits = val;
            % fontsize
            case 'fontsize'; fontsize = val; fontFlag = 1;
            % DPI
            case 'dpi'; dpi = val;
            otherwise; error('Unknown option: %s',name);
            end
        end
        iarg = iarg+incr;
    end
    % enforce various argument-combo limitations
    assert(~(templateFlag && (lenFlag || fontFlag)),'Can input EITHER journal template OR custom width/height specifications.');
    assert(~(ratioFlag && (aRowFlag || aColFlag)),'Can input EITHER aspect ratio spec for rows/columns OR row/column axes extent ratios.');
    assert(~(aRowFlag && aColFlag),'Can input EITHER row OR column aspect ratio spec, not both.');
    % fix units
    switch lower(units)
    case 'inches'; scale = 1;
    case 'points'; scale = 1/72;
    case 'pixels'; scale = pix_to_in;
    otherwise; error('Unknown unit: %s',units);
    end
    % fix font units
    switch lower(fontunits);
    case 'inches'; fontscale = 1/72;
    case 'points'; fontscale = 1;
    case 'pixels'; fontscale = pix_to_pt;
    otherwise; error('Unknown unit: %s',fontunits);
    end

%----------------------------------------------------------------------------------------------------
% Overall figure, font, object properties based on template or manual input
%----------------------------------------------------------------------------------------------------
    %% Template text/figure setup properties
    % template parse
    if ~iscell(template); template = {template}; end
    assert(all(cellfun(@ischar,template)) && length(template)<3,'Bad input. Must be string or 1by2/2by1 cell-array of strings.');
    primary = template{1};
    if length(template)==2; secondary = template{2}; end
    % load templates
    switch primary
    case 'movie'
        % need special DPI
        dpi = pix_to_in; % when printing PNG, use this DPI
        % font sizes
        fontsize = [14 16 20]*pix_to_pt;
        % figsize restrictions
        height = 720*pix_to_in;
        holdY = 1; % NOTE holdX is zero! just want "720p" and will let x-axis expand
    case 'grl' % Geophysical Research Letters
        % figsize restrictions
        switch secondary
        case '1col'; width = 3.32153;
        case '2col'; width = 6.80914;
        case 'long'; height = 6.80914;
        otherwise; error('Unknown size-type %s for GRL journal.',secondary);
        end
    case 'jc' % Journal of Climate
        % ...add to this
    end
    %% Fontsize overwrite
    assert(numel(fontsize)==3 && isnumeric(fontsize) && all(fontsize>3),'Bad font size input. Must be 1by3/3by1 vector of sizes.');
    fontsize = fontsize*fontscale;
    axFontSize = fontsize(1);
    labFontSize = fontsize(2);
    abcFontSize = fontsize(3);
    %% Object/property sizes dependent on font size
    % graphic object sizes
    markerSize =  0.15*axFontSize;
    lineWidth =     0.1*axFontSize;
    hatchlineWidth = 0.07*axFontSize; % should be smaller
    % subplot separations -- scaled by font size
    hugesep =   1.6*axFontSize/72;
    bigsep =    1.2*axFontSize/72;
    medsep =    0.8*axFontSize/72;
    smallsep =  0.5*axFontSize/72; % .8 .5 1 1.6 also try
    tinysep =   0.25*axFontSize/72; % .8 .5 1 1.6 also try
    % default row/column separations
    defaultMargins = [medsep tinysep];
    % unit size options
        % OLD: % tinyunit = .75; smallunit = 1; medunit = 1.5; bigunit = 2; hugeunit = 2.5;
    tinyunit =  5*axFontSize/72;
    smallunit = 8*axFontSize/72;
    medunit =   12*axFontSize/72;
    bigunit =   18*axFontSize/72;
    hugeunit =  25*axFontSize/72;

%----------------------------------------------------------------------------------------------------
% Basic figure properties; axes and figure sizes, subplot stuff
%----------------------------------------------------------------------------------------------------
    %% SubpArray
    subpIDs = unique(subpArray); 
    nsub=numel(subpIDs);
    ncol = size(subpArray,2); nrow = size(subpArray,1); % width/height in "number of axes"
    % basic checks
    assert(ndims(subpArray)==2 && isnumeric(subpArray),'Bad subplot array format. Must be 2D numeric array.');
    assert(all(diff(subpIDs)==1) && numel(subpIDs)==max(subpIDs) && min(subpIDs)==1,'Subplot identifiers should go from 1 to Nsubplot.'); 
    % now make sure numbers form "squares", and get their bottom-left corners and extents
    for ii=1:nsub
        [y,x] = find(subpArray==subpIDs(ii)); xy = [y(:) x(:)];
        for ix=min(x):max(x); for iy=min(y):max(y);
            assert(any(all(xy==repmat([iy ix],[nf 1]),2)),'Subplot IDs in subplot array must from rectangle/square.');
        end; end
    end
    %% total figure width/height 
    % parse "figsize"
    if figsizeFlag;
        assert(isnumeric(figsize) && (numel(figsize)==2 || numel(figsize)==1),'Bad "Size" input.');
        width = figsize(1); height = figsize(end);
    end
    % now width/height
    assert(isscalar(width) && isnumeric(width),'Bad "Width" input.');
    assert(isscalar(height) && isnumeric(height),'Bad "Height" input.');
    width = width*scale; height = height*scale;
%    width, height
    % holdX/holdY stuff
    holdX = 0; holdY = 0;
    if width>0; holdX = 1; end
    if height>0; holdY = 1; end
    %% unitWidth/unitHeight
    % parse "unit"
    if unitFlag;
        assert(isnumeric(unit) && (numel(unit)==2 || numel(unit)==1),'Bad "Unit" input.');
        unitWidth = unit(1); unitHeight = unit(end);
    end
    % main
    units = {unitWidth unitHeight}; lengths = [ncol nrow]; tots = [width height]; fixcheck = [holdX holdY];
    for ii=1:2
        if fixcheck(ii)
            units{ii} = tots(ii)/lengths(ii);
        else
            % test
            assert((isnumeric(units{ii}) && isscalar(units{ii}) && units{ii}>0) || ischar(units{ii}),'Bad "UnitWidth"/"UnitHeight" input.');
            % parse/scale
            if ischar(units{ii});
                switch lower(units{ii}(1))
                case 't'; units{ii} = tinyunit;
                case 's'; units{ii} = smallunit;
                case 'm'; units{ii} = medunit;
                case {'b','l'}; units{ii} = bigunit;
                case 'h'; units{ii} = hugeunit;
                otherwise; error('Unknown size template: %s',margins{ii}{jj});
                end
            else
                units{ii} = units{ii}*scale;
            end
        end
    end
    unitWidth = units{1}; unitHeight = units{2};

%----------------------------------------------------------------------------------------------------
% Modification to subplot (row/column ratios, margins)
%----------------------------------------------------------------------------------------------------
    %% Row/Col-Ratios
    ratios = {rowRatio,colRatio}; lengths = [nrow ncol];
    for ii=1:2
        % modify
        if isscalar(ratios{ii}) && all(ratios{ii})==1; ratios{ii} = ones(lengths(ii),1); end
        % now test
        assert(isnumeric(ratios{ii}) && length(ratios{ii})==lengths(ii) && all(ratios{ii})>0,'Bad "row-ratio" input.');
        % scale such that sum(ratios)==lengths(ii)
        ratios{ii} = ratios{ii}*lengths(ii)/sum(ratios{ii});
    end
    rowRatio = ratios{1}; colRatio = ratios{2};
    %% Margins
    margins = {rowMargin,colMargin}; lengths = [nrow-1 ncol-1];
    for ii=1:2
        if lengths(ii)==0
            margins{ii} = [];
        else
            % modify
            if isempty(margins{ii}); margins{ii} = defaultMargins(ii); end
            if ischar(margins{ii}) || (isnumeric(margins{ii}) && isscalar(margins{ii})); margins{ii} = {margins{ii}};
            elseif isnumeric(margins{ii}); margins{ii} = mat2cell(margins{ii}(:),ones(numel(margins{ii}),1),1);
            end
            if isscalar(margins{ii}); margins{ii} = repmat(margins{ii},[lengths(ii) 1]); end
            % now test
            assert(numel(margins{ii})==lengths(ii) && all(cellfun(@(x)((isnumeric(x) && isscalar(x) && x>0) || ischar(x)),margins{ii})),'Bad margin input.');
            % and parse the character inputs
            charcheck = cellfun(@ischar,margins{ii});
            for jj=1:lengths(ii)
                if charcheck(jj);
                    switch lower(margins{ii}{jj}(1));
                    case 't'; margins{ii}{jj} = tinysep;
                    case 's'; margins{ii}{jj} = smallsep;
                    case 'm'; margins{ii}{jj} = medsep;
                    case {'b','l'}; margins{ii}{jj} = bigsep;
                    case 'h'; margins{ii}{jj} = hugesep;
                    otherwise; error('Unknown size template: %s',margins{ii}{jj});
                    end
                else 
                    units{ii} = units{ii}*scale;
                end
            end
        end
    end
    rowMargin = cell2mat(margins{1}); colMargin = cell2mat(margins{2});

%----------------------------------------------------------------------------------------------------
% Further modifications to subplot array (weird aspect-ratio stuff)
%----------------------------------------------------------------------------------------------------
    %% Parse aspect-ratio input
        % NOTE tests are similar to margin-input tests
    ARs = {rowAR, colAR}; lengths = [nrow ncol];
    for ii=1:2
        % modify
        if isempty(ARs{ii}); ARs{ii} = 1; end
        if ischar(ARs{ii}) || (isnumeric(ARs{ii}) && isscalar(ARs{ii})); ARs{ii} = {ARs{ii}};
        elseif isnumeric(ARs{ii}); ARs{ii} = mat2cell(ARs{ii}(:),ones(numel(ARs{ii}),1),1);
        end
        if isscalar(ARs{ii}); ARs{ii} = repmat(ARs{ii},[lengths(ii) 1]); end
        % now test
        assert(numel(ARs{ii})==lengths(ii) && all(cellfun(@(x)((isnumeric(x) && isscalar(x) && x>0) || ischar(x)),ARs{ii})),'Bad aspect-ratio input.');
        % and parse the character inputs (NOTE probably better to just remember these manually...)
        charcheck = cellfun(@ischar,ARs{ii});
        for jj=1:lengths(ii)
            if charcheck(jj);
            switch lower(ARs{ii}{jj});
            case 'pcarree'
                ARs{ii}{jj} = .5; % [-90,90] latitudes / [0,360] longitudes
            case {'eqdazm','eqaazm'} % for polar azimuthal plots e.g.
                ARs{ii}{jj} = 1;
            otherwise; error('Unknown Aspect-Ratio spec. string: %s',ARs{ii}{jj});
            end
            end
        end
    end
    rowAR = cell2mat(ARs{1}); colAR = cell2mat(ARs{2});
    %% Modify unitWidth/height and rowratio/colratio based on aspect-ratio input
    % rowRatio/colRatio and unitWidth/height are the ones ACTUALLY USED in constructing the subplot array
    if aRowFlag
        % labelled aspect-ratios of each subplot in ROW
        colRatio = ones(ncol,1);
        rowRatio = rowAR*nrow/sum(rowAR);
        if holdX && ~holdY % re-modify unitWidth/unitHeight if total width is fixed; decrease them proportionally
            unitHeight = unitWidth*sum(rowAR)/nrow;
        elseif ~holdX % unitWidth fix; have sum(AR) = EACH COLUMN-AR, so unitWidth = (unitHeight*nrow)/sum(AR)
            unitWidth = (unitHeight*nrow)/sum(rowAR);
        else; error('Cannot implement requested aspect ratios. Either figure width/height must be unrestricted.');
        end
    end
    if aColFlag
        rowRatio = ones(nrow,1);
        colAR = 1./colAR; % transform from y/x to x/y, and "y" matches for each subplot in a row
        colRatio = colAR*ncol/sum(colAR);
        if holdY && ~holdX % unitHeight fix
            unitWidth = unitHeight*sum(colAR)/ncol;
        elseif ~holdY
            unitHeight = (unitWidth*ncol)/sum(colAR); % colAR is now x/y
        else; error('Cannot implement requested aspect ratios. Either figure width/height must be unrestricted.');
        end
    end

%----------------------------------------------------------------------------------------------------
% Make
%----------------------------------------------------------------------------------------------------
    %% Draw subplot network
    % Will use only unitWidth/unitHeight and the row/column-ratios
    Wstarts = zeros(1,nsub); Hstarts = zeros(1,nsub); Ws = zeros(1,nsub); Hs = zeros(1,nsub);
    for ii=1:nsub
        [ys,xs] = find(subpArray==subpIDs(ii)); 
        incorner = [min(xs) max(ys)];
        outcorner = [max(xs) min(ys)];
        Wstarts(ii) = sum(unitWidth*colRatio(1:incorner(1)-1));
        Hstarts(ii) = sum(unitHeight*rowRatio(incorner(2)+1:end));
        Ws(ii) = sum(unitWidth*colRatio(incorner(1):outcorner(1)));
        Hs(ii) = sum(unitHeight*rowRatio(outcorner(2):incorner(2)));
    end
    %% Declare global figure properties
    % text properties
    t = struct();
    axesText = struct('FontSize',axFontSize, 'Color', figureColor, ... % changeable
        'FontName','Helvetica'); % fixed
    legendText = struct('FontSize',axFontSize,'Color',figureColor, ...
        'FontName','Helvetica','FontWeight','bold'); % fixed
    labelText = struct('FontSize',labFontSize,'Color',figureColor, ...
        'FontName','Helvetica'); % fixed
    titleText = struct('FontSize',labFontSize,'Color',figureColor, ...
        'FontName','Helvetica','FontWeight','bold'); % fixed
    ABCText = struct('FontSize',abcFontSize,'Color',figureColor, ...
        'FontName','Helvetica','FontWeight','bold'); % fixed
    % graphic objects
    axesProperties = struct('LineWidth',lineWidth,'Color','white','XColor',figureColor,'YColor',figureColor,'Box','on'); % will be accessed when user declares minor axes, e.g. legends, panels, insets, colorbars
    lineProperties = struct('MarkerSize',markerSize,'LineWidth',lineWidth);
    hatchProperties = struct('LineWidth',hatchlineWidth);
    %% Make axes, figure with userdata
    % edge buffer (so if axis has no external objects, text/lines aren't cut off (e.g. lines are always CENTERED at their specified location, like for axes)
    edgebuffer = [lineWidth/72 lineWidth/72 0 0];
    % declare figure and set ordinary+custom prpoerties
%    f = figure('Units','inches','Position',[1 1 unitWidth*ncol unitHeight*nrow], ...
    f = figure('Units','inches','Position',[1 1 unitWidth*ncol+lineWidth*2/72 unitHeight*nrow+lineWidth*2/72], ...
        'MenuBar','none','DockControls','off','Resize','off'); % disables docking and resizing; NOTE ToolBar by default uses same property as MenuBar
        ... %'InvertHardCopy','off','Color','white'); % so background axes/figure colors are not RESET to white; maybe want transparent, sometimes.
    myset(f,'HandleArray',handleArray, ...
            'HoldX',holdX,'HoldY',holdY, ... % accessed by marginfix
            'RowWidths',unitHeight*rowRatio,'ColWidths',unitWidth*colRatio,... % widths of rows/columns in array; will be accesssed by marginfix
            'HoldAR',HoldAR,'FixStretch',fixStretch, ... % switches; will be accessed by marginfix
            'DPI',dpi, ... % accessed by myprint (for saving bitmap images, always used)
            'Children',a, ... % properties next
            'LineProperties',lineProperties,'HatchProperties',hatchProperties,...
            'DefaultText',axesText,'LegendText',legendText,'LabelText',labelText,'TitleText',titleText,'ABCText',ABCText);
    % make axes
    handleArray = gobjects(size(subpArray)); % object-handle array!
    for id=1:nsub
        % draw
        ipos = [Wstarts(id) Hstarts(id) Ws(id) Hs(id)];
        a(id) = axes('NextPlot','add','SortMethod','childorder','Clipping','on','Tag',... % so user doesn't have to use hold on every time; also childorder doesn't consider Z-dimension (more explicit/reasonable since
            ...% this library is for 2-d plots only) and clipping clips objects past edge. can turn clipping off for INDIVIDUAL lines/patches in their settings
            'Clipping','on',... % this is on by default, but should be explicit; NOTE that line/patch objects have Clipping property too; must ALSO be set to 'on' for axes to work. 
             ... % if axes clipping set to 'off', graphics object 'clipping' setting is ignored
            'XLimMode','manual','YLimMode','manual','XTickMode','manual','YTickMode','manual','XTickLabelMode','manual','YTickLabelMode','manual', ... % disable auto-declaration of ticks
            'XScale','linear','YScale','linear','XDir','normal','YDir','normal', ... % these are default values, but write explicitly anyway
            'XLim',[0 1],'YLim',[0 1],'XTick',NaN,'YTick',NaN,'XTickLabel','','YTickLabel','','Tag',num2str(id), ... % some basic; tag is NUMBER ID (IMPORTANT -- USED TO DIFFERENTIATE "PRIMARY" FROM "SECONDARY" AXES OBJECTS)
            axesProperties); % accepts structure-format input
%        set(a(id),axesProperties); % universal ones
        % set custom propeties
        myset(a(id),'Parent',f, 'Position',ipos+edgebuffer, 'Margin',[0 0 0 0], ... % start with zero writeable margin-space
            'GraphicObjects',gobjects(0,1), ... % will place all line/patch objects in here
            'WestStatus','none','EastStatus','none','SouthStatus','none','EastStatus','none', ... % status: "primary" "secondary" or "none"?
            'YDirWest','normal','YDirEast','normal','XDirSouth','normal','XDirNorth','normal', ... % directions
            'YScaleWest','linear','YScaleEast','linear','XScaleSouth','linear','XScaleNorth','normal', ... % scale
            'YTickWest',[],'YTickEast',[],'XTickSouth',[],'XTickNorth',[], ... % tick marks specific locations
            'YTickSpaceWest',5,'YTickSpaceEast',5,'XTickSpaceSouth',5,'XTickSpaceNorth',5, ... % if tick is empty; we use this: generates ticks at these increments CENTERED AT ZERO
            'YTickMinorWest',[],'YTickMinorEast',[],'XTickMinorSouth',[],'XTickMinorNorth',[], ...
            'YTickMinorSpaceWest',5,'YTickMinorSpaceEast',5,'XTickMinorSpaceSouth',5,'XTickMinorSpaceNorth',5, ...
            'XLimSouth',[0 1],'XLimNorth',[0 1],'YLimWest',[0 1],'YLimEast',[0 1], ...
            'XLimModeSouth','auto','XLimModeNorth','auto','YLimModeWest','auto','YLimModeEast','auto'); % TO START use auto xlim/ylim; if user EVER specifies their own (i.e. fills xlimsouth xlimnorth etc.)
                % then these will forever be set to 'manual' and NO MORE automatic limit generation
        handleArray(subpArray==id) = a(id); % record in a "handle array"
    end
    myset(f,'HandleArray',handleArray);

    %% Apply margins to axes grid (keep commented out stuff; this helps verify that marginfix works if you get errors)
    if writeflag; myprint(f,'./before'); end
    for kk=1:nsub
        poss(:,kk) = myget(a(kk),'Position');
    end
    poss(3:4,:)
    posf=myget(f,'Position'); posf(3:4)
    % row margins
    for ii=1:length(rowMargin)
        % find appropriate axis handle
        x = find(subpArray(ii,:)~=subpArray(ii+1,:));
        if ~isempty(x); % no error; will just ignore that entry
            marginfix(handleArray(ii,x(1)), [0 rowMargin(ii) 0 0], 'nowrite', ['initmargin' num2str(ii) '-'] ); % in "South" position
        end
        for kk=1:nsub
            poss(:,kk) = myget(a(kk),'Position');
        end
        ii
        poss(3:4,:)
        posf=myget(f,'Position'); posf(3:4)
    end
    % column margins
    for jj=1:length(colMargin);
        % find appropriate axis handle
        y = find(subpArray(:,jj)~=subpArray(:,jj+1));
        if ~isempty(y); % no error; will just ignore that entry
            marginfix(handleArray(y(1),jj), [0 0 colMargin(jj) 0 ], 'nowrite', ['initmargin' num2str(jj+length(rowMargin)) '-']); % in "South" position
        end
        for kk=1:nsub
            poss(:,kk) = myget(a(kk),'Position');
        end
        jj
        poss(3:4,:)
        posf=myget(f,'Position'); posf(3:4)
    end
    if writeflag; myprint(f,['./after']); end
