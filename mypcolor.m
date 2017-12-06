function [h] = mypcolor( a, yb, xb, data, varargin )
    % Creates pcolor grid with accessible patch data, and without having to use padarray.
    % Makes behavior consistent with mypcolorm, which can ONLY draw with patch since the 
    % grid is generally warped by the map projection (non-rectangular boxes)
    
    %% Parse/trigger errors
    axes(a);
    assert(length(yb)==size(data,1)-1 && length(xb)==size(data,2)=1,'Input should be y graticule, x graticule, data centers.');
    assert(mod(length(varargin),2)==0,'Invalid arguments. Optional args must be Name-Value pairs.');
    facealpha = 1; edgecolor = 'none';
    for iarg=1:2:length(varargin)-1
        switch lower(varargin{iarg})
        case 'edgecolor'
            edgecol = varargin{iarg+1};
        case 'facealpha'
            facealpha = varargin{iarg+1};
            % NOTE edgealpha should be 1; since objects border each other with different colors, 
            % having transparent edges causes "fuziness" (line is centered on actual edge and different
            % colors seep through)
        otherwise
            error('Invalid name: %s',varargin{iarg});
        end
    end
    %h = pcolor( xb, yb, padarray(data,[1 1],NaN,'post'));

    %% Get patch objects
    ny = size(data,1); nx = size(data,2);
    F = zeros(nx*ny,4);
    % Draw faces
    for ii=1:ny; for jj=1:nx;
        F((ii-1)*jj + jj,:) = ...
            [(ii-1)*(nx+1) + jj ... % LL corner
             ii*(nx+1) + jj ...  % UL corner
             ii*(nx+1) + jj+1 ... % UR corner
             (ii-1)*(nx+1) + jj+1];  % LR corner
    end; end
    % Draw vertices
    V = [repmat(xb(:),[ny+1 1]) squeeze(repmat(yb(:)',[nx+1 1]),[(nx+1)*(ny+1) 1])]; % format is [x1 y1; x2 y1; ...; xN y1; x1 y2; ...; xN y2; ...; x1 yM; ...; xN yM]
    % Allocate CData
    cdata = squeeze(data,[nx*ny 1]);

    %% Get figure default/global properties
    p = myget(get(a,'Parent'),'Properties'); 
    lw = p.LineWidth;

    if ~mapflag;
        %% Draw object
        h = patch( 'Faces',F,'Vertices',V, 'FaceColor','flat', 'CData',cdata, 'EdgeColor',edgecolor, 'FaceAlpha',facealpha, 'LineWidth',lw);
    else
        %% Get axis map type
        map = myget(a,'Map'); maplon = myget(a,'LonEdge'); maplat = myget(a,'LatEdge');
        [V(:,1) V(:,2)] = myproject(map, V(:,2), V(:,1));
        % and draw; but what about faces that CROSS cMeridian+180 / the longitude edge? Slice those ones up.
    end
