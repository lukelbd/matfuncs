function [] = myxtick(ax,varargin) 
    % Simple function for setting up X ticks
    if ishandle(ax);
        assert(strcmpi(get(ax,'type'),'axes'),'Bad handle.');
        assert(numel(varargin)==1,'Bad input.');
        x = varargin{1};
    else
        assert(isempty(varargin),'Bad input.');
        x = ax;
        ax = gca;
    end
    % Action
    set(ax, 'XTick', x); 
