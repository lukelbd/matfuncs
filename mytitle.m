function [ th ] = mytitle ( ax, varargin )
    % My custom title. Axes and figure positions are handled by myfigure;
    % if text is cut off, adjust those properties.
    %
    % Required input: lab, can be string or 1by2/2by1 cell string. If the latter, writes both of them
    % with preset line separation according to setupSizes.m
    %
    % Optional inputs: 'left', 'right', 'center' alignment.
    %
    % ('figstyle',{'movie','print'}) to pass to setupSizes (which selects appropriate fontsizes; movies
    % have large font and myfigure enforces 720pixel height with them; but print have smaller, constant font
    % and more variable size.
    % 
    % 'suptitle' for a large, overarching title. not bound to any one subplot. useful e.g. if you have a bunch of 
    % subplots but want one big title.
    %
    % NEW IDEA: From now on use "tightinset" property when printing to adjust Y-EXTENT of figure, since that
    % doesn't need to be tightly contrained; just want the text to not be cut off, usually. However, X-SCALE should
    % perfectly match the publishers recommendations, or alotted space in a poster, et. cetera. We won't adjust that
    % before printing.
    % ^^^Nope, forget that shit; now I have an awesome new workflow that dynamcally adjusts positions of all objects when
    %    you insert text, etc.
    %
    % DEFINITELY DO THIS: suptitle will take multiple (or even one) axes objects, place invisible axis above the yextent of their
    % individual titles, and write centered title there.

    %% Defaults, parse
    warning('on');
    warning(['Luke, you changed mytitle.m! Now must write "abc","..." for' ...
            'your subplot identifiers, and "lab" input is optional.']);
    align = 'center';
    abc = ''; nolabflag = 1; % label as subplot (1), (a), (I), etc?
    abcflag = 0;
    leftflag = 0; rightflag = 0; marginpass = [];
    abcrightflag = 0;
    suptitleflag = false;
    if ~isempty(varargin)
        iarg = 1;
        while iarg<=length(varargin);
            switch varargin{iarg}
            case {'left','right','center'}
                align = varargin{iarg};
                if strcmp(align,'left')
                    leftflag = true;
                elseif strcmp(align,'right')
                    rightflag = true;
                end
                ndel = 1;
            case 'abc' % specify label 
                abc = varargin{iarg};
                abcflag = 1;
                ndel = 1;
            case {'abcleft','abcright'}
                abcalign = varargin{iarg};
                if strcmp(abcalign,'abcright')
                    abcrightflag = true;
                end
                ndel = 1;
            case 'figstyle'
                marginpass = varargin(iarg:iarg+1);
                ndel = 2;
            case 'suptitle' % super title; write it offset from top
                suptitleflag = true; ndel = 1;
                align = 'center';
            otherwise
                if ischar(varargin{iarg});
                    lab = varargin{iarg};
                    nolabflag = 0;
                    ndel = 1;
                else
                    error('Unknown input.');
                end
            end
            varargin(iarg:iarg+ndel-1) = [];
        end
    end
    % Exit option
    if nolabflag && ~abcflag; warning('on'); warning('Nothing written! You did not specify title or identifier. Exiting...'); end
    % Compensation for outer ticks
    ticklen = 0; % default
    tickd = get(ax,'TickDir'); boxonoff = get(ax,'Box');
    switch boxonoff,
    case 'on';
        switch tickd,
        case {'both','out'}; ticklen = setupSizes('ticklen');
        end,
    end

    %% Defaults, settings
    titlestringset_struct = setupSizes('title',marginpass);  
    subtstringset_struct = setupSizes('subt',marginpass);
    abcstringset_struct = setupSizes('abc',marginpass);
    %titlesep = setupSizes('2linetitlespace',marginpass);
    offs = setupSizes('titleoff') + .25*titlestringset_struct.fontsize/72; % inches from top edge of axis
    abcoffs = ticklen + .1*abcstringset_struct.fontsize/72; 
    set(ax,'Units','inches')
     % Suptitle
    if suptitleflag && abcflag;
        error('This is for a title spanning (potentially) several subplots. Cant have an "abc" label. If you want a 2-line title, just input cell array of strings.');
    end    
    
    %% "ABC" text
    axpos = get(ax,'Position');
    if abcflag
        abcxpos = 0; halign = 'left'; if abcrightflag; abcxpos = axpos(3); halign = 'right'; end
        th(1) = text(abcxpos, axpos(4)+abcoffs, sprintf('(%s)',abc), ...
            'Parent', ax, ...
            'Units', 'inches', ...
            'HorizontalAlignment', halign, ...
            'VerticalAlignment', 'bottom', ... % note parentheses extend to "bottom"
            'Tag','ABC', ...
            abcstringset_struct);
        if nolabflag;
            return
        end
    end
    
    %% Get position for title text
    if iscell(lab)
        twotitleflag = true;
        if suptitleflag; write1st_id = 1; write2nd_id = 2; else; write1st_id = 2; write2nd_id = 1; end
        lab1 = lab{write1st_id};
        lab2 = lab{write2nd_id};
    else
        twotitleflag = false;
        lab1 = lab;
    end
    if leftflag && abcflag;
        set(th(1),'Units','inches');
        extentarr = get(th(1),'Extent');
        xpos = extentarr(1) + extentarr(3) + .5*titlestringset_struct.fontsize/72; % separation is half of Em square
    elseif leftflag
        xpos = 0;
    elseif rightflag;
        xpos = axpos(3);
    else
        xpos = axpos(3)/2;
    end
    % Suptitle
    if suptitleflag % title spans muliple subplots
        fh = get(ax,'Parent'); fun = get(fh,'Units'); set(fh,'Units','inches'); fpos = get(fh,'Position'); set(fh,'Units',fun);
        edgespace = setupSizes('edgespace',marginpass);
        ypos = fpos(4)-axpos(2)-edgespace+offs; xpos = fpos(3)/2-axpos(1);
        valign = 'top';
        %valign = 'top';
    else
        ypos = axpos(4)+offs;
        valign = 'bottom';
        %valign = 'bottom';
    end    

    %% Title (1-line case) or subtitle /subtitle text (2-line case)
    if twotitleflag;
        if suptitleflag; struct1 = titlestringset_struct; struct2 = subtstringset_struct;
        else; struct2 = titlestringset_struct; struct1 = subtstringset_struct;
        end
    else; struct1 = titlestringset_struct;
    end
    th(1+abcflag) = text(xpos, ypos, lab1, ...
           'Parent', ax, ...
           'Units', 'inches', ...
           'HorizontalAlignment', align, ...
           'VerticalAlignment', valign, ...
           'Tag','Title', ...
           struct1); % IF INPUT TWO LINES, THIS IS "MAIN TITLE"; IF NOT, THIS IS SUBTITLE
        
    %% Title (2-line case)
    if twotitleflag
        if suptitleflag; newypos = ypos-1.275*struct2.fontsize/72;
            %newypos = ypos-titlesep-struct2.fontsize/72;
        else; newypos = ypos+1.275*struct2.fontsize/72;
            %newypos = ypos+titlesep+struct2.fontsize/72;
        end
        th(2+abcflag) = text(xpos, newypos, lab2, ...
           'Parent', ax, ...
           'Units', 'inches', ...
           'HorizontalAlignment', align, ...
           'VerticalAlignment', valign, ...
           'Tag','Title', ...
           struct2);
    end
end
