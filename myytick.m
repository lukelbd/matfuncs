function [] = myytick(ax,varargin) 
    % Simple function for setting up Y ticks
    if ishandle(ax);
        assert(strcmpi(get(ax,'type'),'axes'),'Bad handle.');
        assert(numel(varargin)==1,'Bad input.');
        y = varargin{1};
    else
        assert(isempty(varargin),'Bad input.');
        y = ax;
        ax = gca;
    end
    % Action
    set(ax, 'YTick', y); 
