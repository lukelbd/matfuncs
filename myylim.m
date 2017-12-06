function [] = myylim(ax,varargin) 
    % Setups up ylim to minimium/maximum values in array
    if ishandle(ax);
        assert(strcmpi(get(ax,'type'),'axes'),'Bad handle.');
        assert(numel(varargin)==1,'Bad input.');
        y = varargin{1};
    else
        assert(isempty(varargin),'Bad input.');
        y = ax;
        ax = gca;
    end
    assert(numel(y)>1,'Need at least two elements.');
    % Action
    y = y(:);
    set(ax, 'YLim', [min(y) max(y)]); % just set YLim... incidently, why don't you just use "ylim" then?
