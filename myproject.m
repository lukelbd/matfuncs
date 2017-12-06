function [] = myproject ( name, lat, lon, varargin )
    % Usage:
    % [] = myproject( name, lat, lon, [OptionalArgs])
    %   where OptionalArgs can include:
    %       PoleFlag
    %       cMeridian
    %       stdParallel
    %   depending on the projection.
    %
    % [] = myproject( a, lat, lon) 
    %   where a is an AXIS HANDLE with map-projection already activated
    %
    % NOTE should include orthographic; ALSO for some CONIC map projections, consider generalizing them
    % and defining a BOX using lower-left corner and upper-right corner longitudes/latitudes by which 
    % the map is ENCLOSED. would then enforce constant aspect ratio on the axes for the rectangle. though problem then...
    % setup.m would need new axes objects

    % Parse input
    if isobject(name);
        % pull map info from UserData
        ob = name;
        name = myget(ob,'Map');
        assert(isempty(varargin),'Too many input arguments.');
        varargin = myget(ob,'MapArgs'); % a cell-array of secondary arguments
    end
    % Driver function that gets projections for coordinates x, y, name
    func = str2func(lower(name));
    try 
        [ x,y ] = func(lat, lon, varargin);
    catch e
        error('Invalid projection name: %s. Valid names: %s',name,strjoin({'WinkelTripel','Hammer','Aitoff','EqdAzm','EqaAzm','PCarree'},', '));
    end

%% Coordinate transformations
% NOTE need to fix varargin; will be passed as {varargin}
function [ x,y ] = winkeltripel( lat, lon, varargin )
    % NOTE Winkel-Tripel is average of equirectangular and Aitoff
    varargin = varargin{1};
    % parse, setup
    cMeridian = 0; stdParallel = 0;
    if length(varargin)>0;
        cMeridian = varargin{1};
        if length(varargin)>1;
            stdParallel = varargin{2};
        end
    end
    lambda = (lon-cMeridian)*pi/180;
    phi = lat*pi/180;
    phi1 = stdParallel*pi/180;
    % Winkel coordinates
    Alpha = acos(cos(phi).*cos(lambda/2));
    x = 0.5*(lambda.*cos(phi1) + (2*cos(phi).*sin(lambda/2))./(sin(Alpha)./Alpha));
    y = 0.5*(phi + sin(phi)./(sin(Alpha)./Alpha));

function [ x,y ] = mollweide( lat, lon, varargin)
    % NOTE like aitoff/hammer, but parallels are parallel
    % parse, setup
    cMeridian = 0;
    precision = .01;
    if length(varargin)>0;
        cMeridian = varargin{1};
    end
    lambda = (lon-cMeridian)*pi/180;
    phi = lat*pi/180;
    % solve for theta by iteration
    theta0 = phi;
    for ii=1:numel(theta0)
        n = 0;
        while n<50; % NOTE we index with scalars; will pass down dimensions incrementally
            theta(ii) = theta0(ii) - (2*theta0(ii) + sin(2*theta0(ii)) - pi*sin(phi(ii)))/(2+2*cos(2*theta0(ii)));
            if abs(theta(ii)-theta0(ii))<precision; break; end
            n = n+1; theta(ii) = theta0(ii);
        end
        if n==50; error('Did not converge.'); end
    end
    % Mollweide coordinates (unscaled from the Wikipedia equations)
    x = (2/pi)*lambda.*cos(theta);
    y = sin(theta);

function [ x,y ] = hammer( lat, lon, varargin )
    % NOTE aitoff is to azimuthal equidistant as hammer is to azimuthal equal-area; hammer is more common
    varargin = varargin{1};
    % parse, setup
    cMeridian = 0;
    if length(varargin)>0;
        cMeridian = varargin{1};
    end
    lambda = (lon-cMeridian)*pi/180;
    phi = lat*pi/180;
    % Hammer coordinates
    x = (2*sqrt(2)*cos(phi).*sin(lambda/2))./(sqrt(1+cos(phi).*cos(lambda/2)));
    y = (sqrt(2)*sin(phi))./(sqrt(1+cos(phi).*cos(lambda/2)));

function [ x,y ] = aitoff( lat, lon, varargin )
    % NOTE aitoff is to azimuthal equidistant as hammer is to azimuthal equal-area
    varargin = varargin{1};
    % parse, setup
    cMeridian = 0;
    if length(varargin)>0;
        cMeridian = varargin{1};
    end
    lambda = (lon-cMeridian)*pi/180;
    phi = lat*pi/180;
    % Aitoff coordinates
    Alpha = acos(cos(phi).*cos(lambda/2));
    x = (2*cos(phi).*sin(lambda/2))./(sin(Alpha)./Alpha);

function [ x,y ] = eqdazm( lat, lon, Pole, varargin )
    varargin = varargin{1};
    % parse, setup
    switch lower(Pole(1))
    case 'n'; fact = 1;
    case 's'; fact = -1;
    end
    cMeridian = 0;
    if length(varargin)>0;
        cMeridian = varargin{1};
    end
    rho = fact*(pi/2 - lat*pi/180);
    theta = (lon-cMeridian)*pi/180;
    % Polar eqdazm
    x = rho.*sin(theta);
    y = -rho.*cos(theta); % e.g. theta is zero, then coordinate extends down from center pole in vertical line

function [ x,y ] = eqaazm( lat, lon, Pole, varargin ) 
    varargin = varargin{1};
    % parse, setup
    switch lower(Pole(1))
    case 'n'; fact = 1;
    case 's'; fact = -1;
    end
    cMeridian = 0;
    if length(varargin)>0;
        cMeridian = varargin{1};
    end
    lambda = (lon-cMeridian)*pi/180;
    k = cos(phi).*sqrt(2./(1+fact*sin(phi)));
    % Polar eqaazm
    x = k.*sin(lambda);
    y = -(k*fact).*cos(lambda);

function [ x,y ] = pcarree( lat, lon, varargin )
    varargin = varargin{1};
    % parse, setup
    cMeridian = 0; stdParallel = 0;
    if length(varargin)>0;
        cMeridian = varargin{1};
        if length(varargin)>1;
            stdParallel = varargin{2};
        end
    end
    % Plate Carree (equirectangular)
    x = (lon-cMeridian)*pi/180;
    y = (lat-stdParallel)*pi/180;

