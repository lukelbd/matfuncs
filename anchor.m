function [ ] = myanchor( obs, hpars, anchors, varargin )
    % Anchors AXES objects (e.g. insets, colorbars, etc.) to a particular axis, 
    % to a row of axes, etc. For most text objects, we use regular positioning. Also re-positions 
    % anchored objects. Should be run AFTER myposfix is done. 
    % NOTE: "Buffer" and "Extent"+"Anchor" properties may be redundant for axes. Consider revising.
    % NOTE: myanchor ASSIGNS 'Parent' PROPERTY! Do not assign it in main functions; should just assign for text objects, e.g.
    %
    % Usage: [] = myanchor( ob, hpars, anchors, [buffer], [alignkey] ) % for setting up anchored objects for the first time
    %        [] = myanchor( obs ) % for resetting anchored objects using their UserData info
    %
    % Buffer can be scalar (in which case 2-d offset is *implied*) or 1by2/2by1 vector (explicitly specifies 2-d offset)
    %
    % Can also enforce matching x/y extent. Currently only have ability to force x/y extent/location to match x/y extent/location of a parent axis; 
    % cannot scale these to be some proportion along axis, e.g. Is unnecessary I think; panels generally should match dimensions
    % and colorbars/suptitles are graphics objects (patch/text) with invisible underlying axes.
    %

    %% Initial stuff for 2 modes
    resetflag = 0;
    if nargin==1;
        resetflag = 1;
        obloop = 1:length(obs)
    else
        resetflag = 0;
        obloop = 1;
    end

    %% Loop through objects
    for iob=1:obloop
        ob = obs(iob);
        if resetflag;
            %% Read object metadata
            alignkey = myget(ob,'Stretch');
            buffer = myget(ob,'Buffer');
            anchors = myget(ob,'Anchor');
            hpars = myget(ob,'Parent');
%            obInfo = get(ob,'UserData'); obtag = get(ob,'Tag');
%            switch lower(obtag); case {'colorbar','suptitle','legend','inset','panel'}; otherwise; error('Object does not appear to be anchored.'); end
%            assert(isfield(obInfo,'Parent') && isfield(obInfo,'StretchAlign') && isfield(obInfo,'Anchors') && isfield(obInfo,'Buffer'),...
%                    'Object UserData is missing field "Parent", "StretchAlign", "Buffer", or "Position"');
%            alignkey = obInfo.StretchAlign;
%            anchors = obInfo.Anchors;
%            buffer = obInfo.Buffer; % horizontal/vertical offset from anchors
%            hpars = obInfo.Parent;
        else
            %% Parse input
%            buffer = [0 0]; alignkey = 'n';
            buffer = [0 0]; alignkey = false;
            assert(length(varargin)<3,'Too many input arguments.');
            for iarg=1:length(varargin)
                if isnumeric(varargin{iarg})
%                    alignkey = lower(varargin{iarg}(1));
                    alignkey = varargin{iarg};
                elseif isnumeric(varargin{iarg})
                    buffer = varargin{iarg};
                else; error('Bad input argument.');
                end
            end
            % convert string anchors to lower-case
            anchors(cellfun(@ischar,anchors)) = lower(anchors(cellfun(@ischar,anchors)));
        end

        %% Process object handles
        % child requirements
        obtp = get(ob,'Type');
        assert(strcmpi(obtp,'axes'), 'Can only anchor axes objects. Currently suptitle, colorbar, and legend are all axes objects.');
        % parent requirements
        npar = length(hpars);
        partype = get(hpars,'Type'); if ~iscell(partype); partype = {partype}; end; 
        assert(all(cellfun(@(x)strcmpi(x,'axes'),partype)) || (npar==1 && strcmpi(partype{1},'figure')), ...
                'Parent objects can be axes, or 1 figure.');

        %% Enforce anchor/buffer specifier format
        figflag = strcmpi(partype{1},'figure'); 
        data_anchor_flag = isnumeric(anchors{1}) && numel(anchors{1})==2;
        assert(~figflag || (figflag && npar==1), 'For figure parent, can only input one axis.');
        assert(isnumeric(buffer) && (numel(buffer)==1 || numel(buffer)==2), ...
            'Bad buffer input.');
        assert( (data_anchor_flag && ~figflag && npar==1 && all(buffer)==0) ... % data anchor
                || (isnumeric(anchors{1}) && numel(anchors{1})==1)  ... % scalar id
                || (ischar(anchors{1}) && any(numel(anchors{1})==[1 2])), ... % name
            'Bad parent anchor specifier. Options are scalar number, cardinal direction string ("NW","N",etc.), or "data units" (in which case parent must be 1 axis, and buffer is set to 0).');
        assert( (isnumeric(anchors{2}) && numel(anchors{2})==1) ... % scalar id
                || (ischar(anchors{2}) && (numel(anchors{2})==1 || numel(anchors{2})==2)), ... % name
            'Bad child anchor specifier.');
        % enforce ZERO buffer for axes anchored to DATA location, since makes things unnecesarily complex and makes more sense to 
        % anchor specific side/corner to some datapoint anyway
        if data_anchor_flag; buffer = 0; end
        % some more conditional checks are made below

        %% Positions
        obpos = myget(ob,'Position');
        parpos = myget(hpars,'Position');
        % record all positions for axes parents
        if npar>1; parpos = cat(1,parpos{:}); end
        % change "position" for figure parent (want parent location of lower-left-hand corner w.r.t. figure; for figure this is trivially [0 0])
        if figflag
            margin = myget(hpars,'Margin');
            parpos = [margin(1) margin(2) parpos(3)-sum(margin([1 3])) parpos(4)-sum(margin([2 4]))];
        end

        %% Get parent anchor position 
%% OLD: Now just access handleArray to figure out where to place objects
%%        % determine LHS/RHS/top/bottom of GROUP
%%        if npar==2
%%            [~,wid] = min(parpos(:,1)); eid = 3-wid; %eid = max(parpos(:,1)+parpos(:,3)); %eid = 3-wid; % for the "stretch" part
%%            [~,sid] = min(parpos(:,2)); nid = 3-sid;
%%            % check that objects are aligned
%%        else
%%            wid = 1; eid = 1; nid = 1; botttid = 1;
%%        end
        % get PARENT OBJECT anchor
        checkparents = @assert(npar==1,'If you wish to anchor object to corner/center of parent, should use 1-axis or 1-figure parent. Input was 2-axis.');
        if data_anchor_flag 
            % initial stuff
            XLim = get(hpars,'XLim'); YLim = get(hpars,'YLim'); 
            % direction fix
            XDir = get(hpars,'XDir'); YDir = get(hpars,'YDir');
            switch lower(XDir); case 'reverse'; XLim = flip(XLim); end; switch lower(YDir); case 'reverse'; YLim = flip(YLim); end
            % scale fix
            XScale = get(hpars,'XScale'); YScale = get(hpars,'YScale'); 
            xbase = XLim(1); ybase = YLim(1); % add-offset base for unit conversion
            xfun = @(x)x; yfun = @(y)y;
            switch lower(XScale); case 'log'; xfun = @log; end; switch lower(YDir); case 'log'; yfun = @log; end
            % conversion factor
            XDataToInch = parpos(3)/diff(xfun(XLim)); YDataToInch = parpos(4)/diff(yfun(YLim));
            anchpos = [(anchors{1}(1)-xfun(XLim(1)))*XDataToInch (anchors{1}(2)-yfun(YLim(1)))*YDataToInch];
        else
            % 2-parent considerations
            if npar>2
                f = get(ob,'Parent'); % since object is axis, this will be parent we want
                arr = myget(f,'HandleArray');
                [x,y] = arrayfun(@(h)find(arr==h),hpar,'UniformOutput',false); % returns {x1,x2,...} for each find and {y1,y2,..}
                mymin = @(r)cellfun(@(z)min(z),r(:)); mymax = @(r)cellfun(@(z)max(z),r(:)); % returns [min(x1); min(x2); ...] or [max(x1); max(x2); ...], etc.
                minx = mymin(x); miny = mymin(y);
                maxx = mymax(x); maxy = mymax(y);
                % are edges of axes input aligned on WEST?
                wfix = all(minx(1)==minx);
                efix = all(maxx(1)==maxx);
                sfix = all(maxy(1)==maxy); % use maxy here because (remember) high y == farhter DOWN array; South-alignment
                nfix = all(miny(1)==miny);
                % find AXIS ID to use for edge
                [~,wid] = min(wfix);
                [~,eid] = max(efix);
                [~,sid] = max(sfix);
                [~,nid] = min(nfix);
            end
            % anchoring (disallows misalignment for 2-axis parents)
            switch anchors{1}
            case {'n',0}
                if npar>1
                    assert(nfix,'Top edges of axes are not aligned.');
                    hpars = hpars([wid eid]);
                end
                anchpos = [parpos(wid,1)+sum(parpos(eid,[1 3]))/2 sum(parpos(nid,[2 4]))];
                anchtype = 1; % N/S
            case {'e',2}
                if npar>1
                    assert(nfix,'Right edges of axes are not aligned.');
                    hpars = hpars([wid eid]);
                end
                anchpos = [sum(parpos(eid,[1 3])) parpos(sid,2)+sum(parpos(nid,[2 4]))/2];
                anchtype = 2; % E/W
            case {'s',4}
                if npar>1
                    assert(nfix,'Bottom edges of axes are not aligned.');
                    hpars = hpars([wid eid]);
                end
                anchpos = [parpos(wid)+sum(parpos(eid,[1 3]))/2 parpos(sid,2)];
                anchtype = 1;
            case {'w',6}
                if npar>1
                    assert(nfix,'Left edges of axes are not aligned.');
                    hpars = hpars([wid eid]);
                end
                anchpos = [parpos(wid) parpos(sid,2)+sum(parpos(nid,[2 4]))/2];
                anchtype = 2;
            % types allowing only 1 parent
            case {1,'ne'}
                anchpos = [parpos(1)+parpos(3) parpos(2)+parpos(4)];
                anchtype = 3; checkparents;
            case {3,'se'}
                anchpos = [parpos(1)+parpos(3) parpos(2)];
                anchtype = 3; checkparents;
            case {5,'sw'}
                anchpos = [parpos(1) parpos(2)];
                anchtype = 3; checkparents;
            case {7,'nw'}
                anchpos = [parpos(1) parpos(2)+parpos(4)];
                anchtype = 3; checkparents;
            case {-1,'c'}
                anchpos = [parpos(1)+parpos(3)/2 parpos(2)+parpos(4)/2];
                anchtype = 3; checkparents; % corner/center
            otherwise; error('Invalid anchors specifier.');
            end
        end

        %% Fix object x/y extent 
        Xext = obpos(3); Yext = obpos(4); % default -- just preserve x/y extent
%        switch alignkey
%        case 'h'; Xext = [parpos(wid,1) parpos(eid,1)+parpos(eid,3)]; if anchtype~=1; warning('Better to have North/South anchors with horizontal distance fixing.'); end
%        case 'v'; Yext = [parpos(sid,1) parpos(nid,1)+parpos(nid,3)]; if anchtype~=2; warning('Better to have East/West anchors with vertical distance fixing.'); end
%        end
        if alignkey;
            if anchtype==1;     Xext = [parpos(wid,1) parpos(eid,1)+parpos(eid,3)];
            elseif anchtype==2; Yext = [parpos(sid,1) parpos(nid,1)+parpos(nid,3)];
            end
        end
         
        %% Get offset to apply when repositioning child object w.r.t. to its let-hand corner, as determined by the child-object anchor
        %% Also interpret buffer input
        if isscalar(buffer); if buffer==0; buffer = [0 0]; end; end % set to 0by0 vector
        bfix = true; if length(buffer)==2; bfix = false; end  % NOTE will be false if we are resetting position; we already interpreted scalar buffer input
        switch anchors{2}
        case {'c',-1} 
            assert(~bfix,'For "center" child anchor, buffer must be length 2 vector (X/Y offset, inches).'); % no standard behavior
            offset = [-Xext/2 -Yext/2];
        case {'n',0} 
            if bfix; buffer = [0 -buffer]; end % extra space above
            offset = [-Xext/2 -Yext];
        case {'e',2} 
            if bfix; buffer = [-buffer 0]; end % extra space to right
            offset = [-Xext -Yext/2];
        case {'s',4} 
            if bfix; buffer = [0 buffer]; end % extra space below
            offset = [-Xext/2 0];
        case {'w',6} 
            if bfix; buffer = [buffer 0]; end % extra space to left
            offset = [0 -Yext/2];
        case {'ne',1} 
            if bfix; buffer = [-buffer -buffer]; end % extra space away from corner
            offset = [-Xext -Yext];
        case {'se',3} 
            if bfix; buffer = [-buffer buffer]; end % ''
            offset = [-Xext 0];
        case {'sw',5} 
            if bfix; buffer = [buffer buffer]; end % ''
            offset = [0 0];
        case {'nw',7} 
            if bfix; buffer = [buffer -buffer]; end % ''
            offset = [0 -Yext];
        end

        %% Get "edge" if applicable
        switch anchors{1}
        case {'n',0}; edge = 'n';
        case {'e',2}; edge = 'e';
        case {'s',4}; edge = 's';
        case {'w',6}; edge = 'w';
        otherwise; edge = '';
        end

        %% Finally set position using parent anchor, offset (which accounts ffor "child" anchor), buffer (describes the space between them),
        %% and desired x/y extent. Also, save stuff in UserData properties
        set(ob, 'Postion',[anchpos+offset+buffer Xext Yext]);
        myset(ob,   'Buffer',buffer, ...
                    'Anchor',anchors, ...
                    'Parent',hpars, ...
                    'Stretch',alignkey, ...
                    'Edge',edge); 
%        s = get(ob,'UserData'); if isempty(s); s = struct(); end
%        s.Buffer = buffer; 
%        s.Anchors = anchors; % {1,2} where each is either lower-case n/s/nw etc., number, or data pair
%        s.Parent = hpars; 
%        s.StretchAlign = alignkey; % 'n', 'h', or 'v'
%             %we DO NOT save offset or anchpos because these can change as the parent objects are moved/resized; instead have to run this function
    end

