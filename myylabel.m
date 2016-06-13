function [ th ] = myylabel ( ax, lab, varargin )
    % Req input:    ax = figure axes.
    %               lab = label string.
    %
    % Optional input: side: ('left', 'right'), whether is x or y axis label.
    %
    % ('figsize',{'movie','print'}) to pass to
    % mymargins.m; uses different fontsize profiles.
    %
    
    varargin = expandcells(varargin);
    if ~isempty(varargin)
        side = varargin{1}; varargin(1) = [];
    else
        side = 'left';
    end
    marginpass = varargin;

    ticklen = 0; tickdir = get(ax,'TickDir');
    axpos = get(ax,'Position');
    switch tickdir
    case {'out','both'}
        ticklen = get(ax,'TickLen')*max(axpos(3:4)); ticklen = ticklen(1);
    end

    % Find yticklabel
    obj = findobj(ax,'Tag','YTickLabel','Type','hggroup');
    if isobject(obj)
        txt = get(obj,'Children'); % Also want yextent if label is rotated... but since ticklabels are actually pretty much always eactly 1 EM square tall, or less actually (dates, numbers, etc., start from baseline
            % and run to standard "cap", with **no hanging tail**), use fontsize as the text occupation of vertical space. Extent itself is from "bottom" to "top", extra (unneeded) whitespace, 
            % but font height tells you, if your axis label string has hanging tails and is aligned baseline, the point where the string stems will exactly touch the top of the ticklabel text
        max_xext = 0;
        for j=1:length(txt);
            set(txt(j),'String',strtrim(get(txt(j),'String')),'Units','inches'); %String = strtrim(txt(j).String); txt(j).Units
            ext = get(txt(j),'Extent'); ext = ext(3); rot = get(txt(j),'Rotation')*pi/180; fsize = get(txt(j),'FontSize')/72;
            ext = ext*abs(cos(rot)) + fsize*abs(sin(rot));
            max_xext = max([max_xext ext]); % get  extent
            %max_xext = max([max_xext ext{j}(3)]); % get  extent
        end
        offs = max_xext + mymargins('yticklaboff',marginpass); % initial offset is maximum extent of label plus label offset from axis edge
        set(txt,'Units','data'); % back to data units
    else; offs = 0;
    end
    offs = offs + mymargins('ylaboff',marginpass); % offset from either "cap" of ticklab, or from axis itself.

    % Set up label    
    stringset_struct = mymargins('lab',marginpass); 
    set(ax,'Units','inches')
    axpos = get(ax,'Position');
    switch side
    case 'left'
        th = text(-offs-ticklen, axpos(4)/2, lab, ...
                'Parent', ax, ... % set desired axes as parent
                'Units', 'inches', ...
                'HorizontalAlignment', 'center', ...
                ...%'VerticalAlignment', 'baseline', ... % actually use bottom align here, because sometimes have subscripts, etc.
                'VerticalAlignment', 'bottom', ...
                'Rotation', 90, ...
                'Tag','YLabel', ...
                stringset_struct);
    case 'right'
        th = text(axpos(3)+offs+ticklen, axpos(4)/2, lab, ...
                'Parent', ax, ...
                'Units', 'inches', ...
                'HorizontalAlignment', 'center', ...
                ...%'VerticalAlignment', 'cap', ... % "cap" is aligned with topmost content
                'VerticalAlignment', 'top', ...
                'Rotation', 90, ...
                'Tag','YLabel', ...
                stringset_struct);
    end      
end
