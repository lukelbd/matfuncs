function [] = myxlim(ax,varargin) 
    % Sets up xlim to minimium/maximum values in array
    if ishandle(ax);
        assert(strcmpi(get(ax,'type'),'axes'),'Bad handle.');
        assert(numel(varargin)==1,'Bad input.');
        x = varargin{1};
    else
        assert(isempty(varargin),'Bad input.');
        x = ax;
        ax = gca;
    end
    assert(numel(x)>1,'Need at least two elements.');
    % Action
    x = x(:);
    set(ax, 'XLim', [min(x) max(x)]); % just set XLim... incidently, why don't you just use "xlim" then?
