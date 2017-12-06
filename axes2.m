function [ a2 ] = axes2( a, opt )
    % Sets up new axes for extra y- or x-axis
    % USAGE:
    %   [ a2 ] = axes2 
    %       uses default 'gca' for axes, and default new y-axis
    %   [ a2 ] = axes2( a ) 
    %       a==axes handle
    %       uses default new axis location
    %   [ a2 ] = axes2( opt ) 
    %       uses default axes
    %       opt=='x','y','xy', or 'yx' case-insensitive; an x means "new x axis", a y "new y axis"
    %   [ a2 ] = axes2( a, opt )
    %       input both
    assert(nargin<3,'Too many arguments.');
    if exist('a')~=1; % i.e. nargin==0
        a = gca;
    elseif ~ishandle(a); % i.e. user just input 'opt'
        opt = a;
        a = gca;
    end
    if exist('opt')~=1;
        opt = 'y'; % more common to have a right-Y axis than top-X axis
    end
    assert(strcmpi(get(a,'type'),'axes'),'Handle must be axes handle.');
    % Test option
    switch lower(opt)
    case {'x','y','xy','yx'}
    otherwise
        error('Option must be string "x" or "y".');
    end
    % New axes locations
    % ...we force 'box' is 'on' using the extra axis... looks fuck ugly with 3 filled axes, 1 empty one
    oldxloc = get(a,'XAxisLoc');
    switch lower(oldxloc)
    case 'bottom'
        xloc = 'top';
    case 'top'
        xloc = 'bottom';
    end
    oldyloc = get(a,'YAxisLoc');
    switch lower(oldyloc)
    case 'left'
        yloc = 'right';
    case 'right'
        yloc = 'left';
    end
    % Initial setup
    set(a,'Units','norm','Box','off'); % ...again, Box off so we can make new axes
    pos = get(a,'Position');
    a2=axes('Units','norm','YAxisLoc',yloc,'XAxisLoc',xloc, ...
                'Color','none','Box','off', ...
                'XGrid','off','YGrid','off','XMinorGrid','off','YMinorGrid','off');
    set(a2,'Position',pos);
    % Extra stuff
    switch lower(opt)
    case 'x'
        set(a2,'YLim',get(a,'YLim'), ...
                'YDir',get(a,'YDir'), ...
                'YScale',get(a,'YScale'), ...
                'YTick',get(a,'YTick'), ...
                'YMinorTick',get(a,'YMinorTick'), ...
                'YGrid','off', ... % don't need duplicate gridlines
                'YMinorGrid','off');
        % ...also, this shouldn't be how we make 'box' with ticks, etc. on both sides
        % that are identical; just turn 'box' 'on' for that functionality
    case 'y'
        set(a2,'XLim',get(a,'XLim'), ...
                'XDir',get(a,'XDir'), ...
                'XScale',get(a,'XScale'), ...
                'XTick',get(a,'XTick'), ...
                'XMinorTick',get(a,'XMinorTick'), ...
                'XGrid','off', ... % don't need duplicate gridlines
                'XMinorGrid','off');
    end
