function [ th ] = myxlabel(ax, lab, varargin)
    % My special x label. Also use for horizontal colorbars. Should not overlap with ticklabs set
    % with myset, ever -- even the rotated custom date tick labels.
    %
    % Optional input: ('figsize',{'movie','print'}) to pass to
    % mymargins.m; uses different fontsize profiles.
    %

    %% Parse
    iarg = 1; topflag = false;
    while iarg<=length(varargin)
        arg = varargin{iarg};
        if ischar(arg)
            switch arg
            case 'bottom'
                varargin(iarg) = [];
            case 'top';
                topflag = true; varargin(iarg) = [];
            otherwise
                iarg = iarg+1;
            end
        else
            iarg = iarg+1;
        end
    end
    marginpass = varargin;

    %% Settings
    stringset_struct = mymargins('lab', marginpass);    
    set(ax,'Units','inches');
    ticklen = 0; tickdir = get(ax,'TickDir');
    axpos = get(ax,'Position');
    switch tickdir
    case {'out','both'}
        ticklen = get(ax,'TickLen')*max(axpos(3:4)); ticklen = ticklen(1); % adjust for tick length/position
    end

    %% Find xticklabel
    obj = findobj(ax,'Tag','XTickLabel','Type','hggroup');
    if isobject(obj)
        txt = get(obj,'Children'); % Also want yextent if label is rotated... but since ticklabels are actually pretty much always eactly 1 EM square tall, or less actually (dates, numbers, etc., start from baseline
            % and run to standard "cap", with **no hanging tail**), use fontsize as the text occupation of vertical space. Extent itself is from "bottom" to "top", extra (unneeded) whitespace, 
            % but font height tells you, if your axis label string has hanging tails and is aligned baseline, the point where the string stems will exactly touch the top of the ticklabel text
        max_xext = 0;
        for j=1:length(txt);
            set(txt(j),'String',strtrim(get(txt(j),'String')),'Units','inches'); %String = strtrim(txt(j).String); txt(j).Units
            ext = get(txt(j),'Extent'); ext = ext(3); rot = get(txt(j),'Rotation')*pi/180; fsize = get(txt(j),'FontSize')/72;
            ext = fsize*abs(cos(rot)) + ext*abs(sin(rot)); % e.g. if xticklabels rotated 90 degrees, it's all good
            max_xext = max([max_xext ext]); % get  extent
            %max_xext = max([max_xext ext{j}(3)]); % get  extent
        end
        %ext
        offs = max_xext + mymargins('xticklaboff',marginpass); % initial offset is maximum extent of label plus label offset from axis edge
        set(txt,'Units','data'); % back to data units
    else; offs = 0;
    end
    offs = offs + mymargins('xlaboff',marginpass); % offset from either "cap" of ticklab, or from axis itself.

    %% Set up label
    if ~topflag
        axpos = get(ax,'Position');
        th = text(axpos(3)/2, -offs-ticklen, lab, ...
               'Parent', ax, ...
               'Units', 'inches', ...
               'HorizontalAlignment', 'center', ...
               ...%'VerticalAlignment', 'cap', ... % although we often have exponents, etc. in label, "cap" is always at position of uppermost content. don't need "top".
               'VerticalAlignment', 'top', ...
               'Tag','XLabel', ...
               stringset_struct);
    else
        axpos = get(ax,'Position');
        th = text(axpos(3)/2, axpos(4)+offs+ticklen, lab, ...
               'Parent', ax, ...
               'Units', 'inches', ...
               'HorizontalAlignment', 'center', ...
               ...%'VerticalAlignment', 'baseline', ... % 'baseline', ... % IGNORE: tried baseline, but cut off a subscript
               'VerticalAlignment', 'bottom', ...
               'Tag','XLabel', ...
               stringset_struct);
    end
end
