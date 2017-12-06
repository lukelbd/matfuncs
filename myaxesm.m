function [] = myaxesm( a, name, varargin )
    % Function creates custom axesm plots, since Winkel-Tripel not available and for other reasons. Will draw 
    % own pcolor and lines using coordinates of graticule as determined by the forward- and inverse- projections
    %
    % IDEA: Write mycontourm which uses CONTOURC to generate CDATA MATRIX, and do so after using GEOPADARRAY on
    % the edges; THEN you can WARP the contour coordinates to your special coordinates, and there we go. Should completely
    % forego mapping toolbox, since I've already foregone the vast majority. Will need CONTOUR2PATCH to make my custom 
    % contouring objects since contours often end on edge of plotting area and I can only re-draw them using 
    % patch objects. So, another use for that function! Meanwhile pcolorm would be changed by making patch objects for each box, 
    % then just transforming the 4 vertices to new coordinates. Would use CData on FACES, record the vertices, and 
    % use FaceColor 'flat'. That is simpler. The only COMPLEX thing here is the contouring
    % algorithm, it appears, but contourc does just fine; just need to trick contourc into making *closed* contours, using
    % mycontour2patch.

    %% Parse input
    % Defaults
    frame = 'on'; gridd = 'on';
    % Custom
    assert(mod(length(varargin),2)==0,'Must be name-value pairs.');
    for iarg=1:2:length(varargin)-1
        val = varargin{arg+1};
        switch lower(varargin{iarg})
        case 'pline'
            par = val;
        case 'mline'
            mer = val;
        case 'plabel'
            plabel = val;
        case 'mlabel'
            mlabel = val;
        case 'grid'
            gridd = val;
        case 'frame'
            frame = val;
        case 'plinespan'
            plinespan = val;
        case 'mlinespan'
            mlinespan = val;
        case 'mlim'
            mlim = val;
        case 'plim'
            plim = val;
        otherwise; error('Invalid name: %s',varargin{iarg});
        end
    end

    %% Draw grid and frame
    % will call myproject with "name" to do so
    if strcmpi(frame,'on');
        % draw frame
    end
    if strcmpi(gridd,'on');
        % draw grid
    end

    %% Save metadata
    myset(a,'Map',name);

