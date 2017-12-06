function [ ] = objectfix( ob )
    % Expands margins and reshuffles axis labels/anchored objects based on priority. Calls
    % mymarginfix after completion to set up subplot margins/figure extent.
    %
    %   Usage: [ outsideObExpand ] = myobjectfix(obh)
    %       obh - object handle (hggroup, text, or axes)
    %
    % The FUNDAMENTAL PROBLEM here is:
    %   1) Adjust positions of SOME PARTICULAR objects in consideration of the presence of OTHER PARTICULAR OBJECTS with
    %       "higher priority" anchored to that edge. GET NEW POSITIONS of all these objects. For some objects e.g. text,
    %       multipliers and corner-anchored legends, their presence SHOULD NOT affect other axis subobject locations, but 
    %       should they be modified by others? maybe corner-anchored legends should be aligned at ticklength away in each direction
    %   2) Adjust margins positions for ARBITRARY objects placed/extending beyond axis box, after everything else has been moved
    %       to accomadate the new item
    % The main idea is objects that SOME should be shuffled/prioritized on a certain side (N/W/E/S) of an axis, AND THEN the margin space
    % should be adjusted in a highly generalized way accounting for all objects and their relative positions w.r.t. the axis box. For example, 
    % xticklabels on the left or right edge will invaide the West and East margin space; these spaces should be expanded after their insertion
    % to account for this effect.
    % 
    % NOTE e.g. for polar azimuthal projections, sometimes make longitude labels outside plotting area, 
    % so our text detection function really must be completely generalized; should make space for those.
    % NOTE potential issue; if we declare axes-spanning ylabel, then write yticklabels for both top and bottom axis, won't the label be reshuffled
    % outward TWICE? solution would be to record an "ORIGINAL EXTENT" property, then re-position precisely at the maximum extent of lower-priority objects]
    % PLUS the original extent

    %% Adjust object position and determine final margin "expand factor" of its parent axis
    [parPos, parMargin, marginWrite] = parentProperties(ob);
    marginExpand = obSetup(ob, parPos, parMargin);
        % NOTE obSetup takes so many arguments because I wanted marginWrite to be 
        % available in the main body of this function, for when we write the "margin" properties

    %% Adjust parent axis, if object was child to colorbar/inset/panel
    hpar = myget(ob,'Parent'); % will always be axes/figure
    partag = get(hpar(1),'Tag'); partype = get(hpar(1),'Type');
%    if strcmpi(get(hpar(1),'Type'),'axes'); f = get(hpar(1),'Parent'); else; f = hpar(1); end
%    arr = myget(f,'HandleArray');
%    hparpar = myget(hpar(1),'Parent'); % e.g. ob is xlabel for colorbar (hpar), which is child of axes (hparpar)
%    if strcmpi(get(get(hpar(1),'Parent'),'Type'),'axes') % NOTE DOESN'T WORK e.g. for suptitle anchored to figure (then DO need to readjust)
%    if any(strcmpi(partag,{'colorbar','panel','inset','suptitle','supxlabel','supylabel'})) % NOTE NOT NEEDED ANYMORE; just test if parent is in handlearray
    if strcmpi(partype,'axes') && ~isnan(str2double(partag)) % i.e. parent is NOT a numbered "MAIN AXIS"
        assert(length(hpar)==1,'Something weird happened. Any "margin" objects of colorbars/panels/insets must have ONE such parent. Instead has more than one.');
        %% Write new margins
        oldMargin = myget(hpar,'Margin');
        myset(hpar,'Margin',oldMargin + marginExpand);
        %% Get distance objects outside this one should be pushed; adjust position if child object added some extent to the "inner" edge (e.g. an E-anchored colorbar with ylabel on its LHS)
        ob = hpar;
        obEdge = myget(ob,'Edge');
        posFix = [0 0 0 0]; outsidePush = [0 0 0 0];
        shuffle = false; % we ALREADY will have panel/colorbar in the position we wanted (the "manual" shuffle below accounting for declared "inside"-edge panel sub-objects)
        displace = true; % we SHOULD displace other objects anchored to the SAME EDGE to account for expansion; will use "outsidePush"
        % get position-fix factor and "offset" array for pushing objects on the same edge out of the way
        switch lower(obEdge(1))
        case 'w'; posFix(1) = -marginExpand(3); outsidePush(1) = sum(marginExpand([1 3])); %if any(strcmpi(obedge,{'w','e'})); shuffle = true; end
        case 'e'; posFix(1) = marginExpand(1);  outsidePush(3) = sum(marginExpand([1 3])); %if any(strcmpi(obedge,{'w','e'})); shuffle = true; end
        case 's'; posFix(2) = -marginExpand(4); outsidePush(2) = sum(marginExpand([2 4])); %if any(strcmpi(obedge,{'n','s'})); shuffle = true; end
        case 'n'; posFix(2) = marginExpand(2);  outsidePush(4) = sum(marginExpand([2 4])); %if any(strcmpi(obedge,{'n','s'})); shuffle = true; end
        otherwise; displace = false; % for insets, e.g.; don't displace anything
        end
        %% Write new position
        % set new position 
        obPos = myget(ob,'Position'); % we already know it is not hggroup or text; "position" is 1by4
        myset(ob,'Position',obPos + posFix); % so move panel/whatever over if it is an INNER label, etc.
        % reset buffer
        if isproperty(ob,'Buffer');
            buffer = myget(ob,'Buffer');
            myset(ob,'Buffer',buffer + posFix(1:2));
        end
        % get NEW parent properties
        [parPos, parMargin, marginWrite] = parentProperties(ob);
            % NOTE we OVERWRITE the previous parPos, parMargin, etc.; those were actually for the inset/panel/colorbar
        % and now get new extent, while adjusting other objects if necessary
        marginExpand = obSetup(ob, parPos, parMargin, shuffle, displace, outsidePush);
    end
        %^^^ in above loop, importantly, "ob" is now the colorbar/inset/panel whose OWN margins have been expanded

    %% Get the marginsAdd parameter (margin expansion that must be applied to each axis)
    % get parent
    hpar = myget(ob,'Parent'); % remember hpar are always ordered left-to-right or bottom-to-top
    margins = myget(ob,'Margin'); if iscell(margins); margins = cat(1,margins{:}); end
    marginsAdd = zeros(length(hpar),4);
        % ^^^here if margins is 2by4, we distribute the added margin-space appropriately (e.g. panel West-aligned on two stacked subplots, added a title, then the top-margin factor is 
        % only added to the TOPMOST subplot obviously)
    for id=1:4; marginsAdd(marginWrite{id},id) = margins(marginWrite{id},id) + marginExpand(id); end
    %myset(hpar(1),'Margin',margins(1,:) + marginsAdd(1,:));
    %if length(hpar)==2; myset(hpar(2),'Margin',margins(2,:) + marginsAdd(2,:)); end
        % NOTE perhaps better to set up margins all-in-one go, make sure they are all synced, as below

    %% Call marginfix
    marginfix(hpar, marginsAdd);

function [ marginExpand ] = obSetup( ob, parPos, parMargin, varargin )
    % Function for writing "extent" property for first time AND adjusting other object extents, reshuffling objects, 
    % etc. when appropriate. In context of these movements, returns "marginExpand", the expand factor for current margins
        % NOTE uses of ShuffleMe and DisplaceYou flags
        % 1) plabels and mlabels can displace objects, but cannot be shuffled themseles
        % 2) multipliers cannot displace objects, but should be shuffled (e.g. due to outside-ticks)
        % 3) most other objects can displace others, and be shuffled
        % 4a) when shuffleflag enabled, the "shuffling direction" is determined by "edge".
        % 4b) when displaceflag enabled, we either displace ONLY ALONG "edge", or if edge is empty, by EXTENT IN EVERY DIRECTION
        % 5) whether either of these is true/false does not matter in terms of their affects on parent margins; 
        %       margin will always be adjusted for their presence

    %% Get initial extent, and load varargin stuff
    if isempty(varargin); assert(length(varargin)==3,'Bad input. For "special" use 3rd input must be shuffleflag, 4th displaceflag, and 5th the "outsidePush" factor.'); end
    obType = get(ob,'Type');
    obEdge = myget(ob,'Edge');
    boxExtent = getObExtent( ob, parPos );
    if ~specialflag
        shuffleflag = get(ob,'ShuffleMe'); 
        displaceflag = get(ob,'DisplaceYou');
        outsidePush = boxExtent;
    else
        shuffleflag = varargin{1}; % shuffle stuff around these objects
        displaceflag = varargin{2};
        outsidePush = varargin{3}; 
    end
    
    %% Consider object in presence of other objects and reshuffle if necessary
    maxExtent = boxExtent; % maxExtent is the extent used for determining how the axis MARGIN EDGES are modified
    if shuffleflag || displaceflag;
        %% Initial stuff
        hpar = myget(ob,'Parent'); set(hpar,'Units','inches');
        ch = myget(hpar,'Children'); % NOTE this can be two objects; objects can 'SHARE' children
        if iscell(ch); ch = [ch{:}]'; end
        ch = ch(ch~=ob);
        % keys
        obkey = getKey(ob);
        keys = getKey(ch);

        %% Determine "shuffling axis"; some NOTES:
        %% 1) edge must be defined if "ShuffleMe" is true (this is true for all objects)
        %% 2a) if edge is undefined and "DisplaceYou" is true, displace all other objects according to this one's extent
        %% 2b) if edge is defined and "DisplaceYou" is true, only displace other objects along that same edge (if they have same "Edge" propertY)
        switch lower(obEdge(1)),
        case 'w'
            edgePosID = 1; edgeExtID = 1; 
            extentDirection = -1; % goes in negative direction (i.e. bigger "W" extent means margin starts further to left, -ve x direction)
        case 's'; 
            edgePosID = 2; edgeExtID = 2; 
            extentDirection = -1;
        case 'e'; 
            edgePosID = 1; edgeExtID = 3; 
            extentDirection = 1; % positive direction
        case 'n'; 
            edgePosID = 2; edgeExtID = 4; 
            extentDirection = 1;
        otherwise; noEdgeFlag = 1;
        end

        %% Shuffle this object if necessary, and write its final Extent/Position
        if shuffleflag 
            if noEdgeFlag; error('Invalid shuffling axis "%s"',obEdge); end
            % get extent of lower-priority inside-stuff
            locsInside = keys<obkey & keys~=999; chInside = ch(locsInside);
            chFilt1 = find(cell2mat(myget(chInside,'DisplaceYou'))==1);
            if ~noEdgeFlag; chFilt2 = cellfun(@(x)strcmpi(x(1),obEdge(1)),myget(chInside,'Edge')); else; chFilt2 = ones(1,length(chInside))==1; end
            chConsiderIDs = find(chFilt1(:) & chFilt2(:));
            insideExtent = myget(chInside(chConsiderIDs),'Extent'); 
            maxInsideExtent = max(cellfun(@(x)x(edgeExtID), insideExtent));
                % NOTE this is the maximum extent among 1) objects with the SAME "EDGE" PROPERTY or 2) any objects
            % get position object to apply to each object or sub-object, and write it
            pos = myget(ob,'Position'); % NOTE myget deals with position for all text/axes objects, and hggroups composed ot text/axes. delivers/records in inches
            offsetPos = zeros(size(pos));
            offsetPos(:,edgePosID) = maxInsideExtent*extentDirection;
            pos = pos + offsetPos;
            myset(ob,'Position',pos);
            % change boxExtent and REWRITE
            offsetExt = [0 0 0 0];
            offsetExt(edgeExtID) = maxInsideExtent;
            boxExtent = boxExtent + offsetExt;
            myset(ob,'Extent',boxExtent);
            % change buffer and WRITE if it is an axes object
            if strcmpi(obType,'axes');
                buffer = myget(ob,'Buffer');
                myset(ob,'Buffer',buffer + offsetPos);
            end
            % modify maxExtent
            maxExtent = boxExtent; % boxExtent has been modified
        end

        %% Displace other objects
        if displaceflag
            % rewrite outside extents
            locsOutside = keys>=obkey & keys~=999; chOutside = ch(locsOutside);
            % write new positions for A) all "outside" objects, or B) "outside" objects
            chFilt1 = cell2mat(myget(chOutside,'ShuffleMe'))==1;
            if ~noEdgeFlag; chFilt2 = cellfun(@(x)strcmpi(x(1),obEdge(1)),myget(chOutside,'Edge')); else; chFilt2 = ones(1,length(chOutside))==1; end
            chMoveIDs = find(chFilt1(:) & chFilt2(:));
            maxOutsideExtent = [0 0 0 0];
            for jj=1:length(chMoveIDs)
                ich = chMoveIDs(jj);
                % determine "displacement axis"; an axis of "NONE" is VALID; just shuffle 
                % will DISPLACE outside stuff by outsidePush on edgeExtId: write their new extents and rewrite their positions
                chedge = get(chOutside(ich),'Edge'); chedge = lower(chedge(1)); 
                switch lower(chedge(1))
                case 'w'
                    edgePosID = 1; edgeExtID = 1; 
                    extentDirection = -1;
                case 's'
                    edgePosID = 2; edgeExtID = 2; 
                    extentDirection = -1;
                case 'e'
                    edgePosID = 1; edgeExtID = 3; 
                    extentDirection = 1;
                case 'n'
                    edgePosID = 2; edgeExtID = 4; 
                    extentDirection = 1;
                otherwise; error('Invalid shuffling axis "%s"',chedge);
                end
                %obExtent = origExtent(edgeExtID);
                obExtent = outsidePush(edgeExtID); % only push along the "extent" ID
                % fix and write POSITIONS
                outsidePos = myget(chOutside(ich),'Position');
                offsetPos = zeros(size(outsidePos));
                offsetPos(:,edgePosID) = obExtent*extentDirection;
                outsidePos = outsidePos + offsetPos;
                myset(chOutside(ich),'Position',outsidePos);
                % now write EXTENTS
                offsetExt = [0 0 0 0];
                offsetExt(edgeExtID) = obExtent;
                outsideExtent = myget(chOutside,'Extent');
                outsideExtent = outsideExtent + offsetExt;
                myset(chOutside(ich),'Extent',outsideExtent);
                % get MAX extents
                maxOutsideExtent = max([maxOutsideExtent; outsideExtent],[],1);
            end
            % modify MAX extent (we've displaced other objects; margin adjust factors might change
            maxExtent = max([maxExtent; maxOutsideExtent],[],1);
        end
    end

    %% Finally, write object extent
    myset(ob,'Extent',boxExtent);

    %% Determine how margins must be modified
    % just compare maxExtent to margins
    marginExpand = max([0 0 0 0; maxExtent - parMargin],[],1);

function [ boxExtent ] = getObExtent( ob, parPos )
    % Returns object extent with repsect to parent position
    %% Some object properties
    tp = get(ob,'Type');
    if strcmpi(tp,'hggroup');
        ch = get(ob,'Children');
        tp = get(ch(1),'Type');
    else; ch = ob;
    end 
    %% Get object POSITION
    switch lower(tp)
    case 'line'
        %% Tick labels
        % this MUST be TICK object, with tick objet properties
        % detect direction
        tickdir = myget(ob,'Dir');
        switch lower(tickdir)
        case {'in','across'} % "across" is for colorbars sometimes
            extentMag = 0;
        case {'both','out'}
            ticklen = myget(ob,'Length'); % length on each side of axis, or across whole thing (option for colorbar)
            extentMag = ticklen;
        otherwise; error('Unknown tick direction code: %s',tickdir);
        end
        % detect if it extends out of axis width
        obEdge = myget(ob,'Edge');
        switch lower(obEdge(1))
        case 'w'; boxExtent = [extentMag 0 0 0]; %marginExpand = [max(0,extentMag-parMargin(1)) 0 0 0];
        case 's'; boxExtent = [0 extentMag 0 0]; %marginExpand = [0 max(0,extentMag-parMargin(2)) 0 0];
        case 'e'; boxExtent = [0 0 extentMag 0]; %marginExpand = [0 0 max(0,extentMag-parMargin(3)) 0];
        case 'n'; boxExtent = [0 0 0 extentMag]; %marginExpand = [0 0 0 max(0,extentMag-parMargin(4))];
        end
    case 'text'
        %% All text objects (including groups of text objects, like ticklabels)
        % NOTE we won't record these text proprties in the various functions, because they can move; also would be awkward to have to make every 
        % text function call some separate "get text position" function every time and save it to userdata
        boxExtent = zeros(length(ch),4);
        for ii=1:length(ch)
            % extent, and vertical/horizontal alignments
            set(ch(ii),'Units','inches');
            iext = get(ch(ii),'Extent'); ipos = get(ch(ii),'Position'); 
            ivalign = get(ch(ii),'VerticalAlignment'); ihalign = get(ch(ii),'HorizontalAlignment');
            irot = get(ch(ii),'Rotation'); irot = mod(irot,360);
            % rotation quadrant location
            quad1 = irot>=0 && irot<90; 
            quad2 = irot>=90 && irot<180; 
            quad3 = irot>=180 && irot<270; 
            quad4 = irot>=270 && irot<360;
            % get location of smallest containing horizontal/vertical box in terms of offset from set "Position"
            % vertical alignment considerations
            switch lower(ivalign)
            case 'bottom'
                if quad3 || quad4; xoff_valign = 0; % bottom edge on left-hand of textbox
                else; xoff_valign = abs(sin(irot*pi/180))*iext(1);
                end
                if quad1 || quad4; yoff_valign = 0; % bottom edge on bottom of textbox
                else; yoff_valign = abs(cos(irot*pi/180))*iext(2);
                end
            case 'middle'
                xoff_valign = abs(sin(irot*pi/180))*iext(1)/2; % quadrant doesn't matter
                yoff_valign = abs(cos(irot*pi/180))*iext(2)/2;
            case 'top'
                if quad1 || quad2; xoff_valign = 0; % top edge on left-hand of textbox
                else; xoff_valign = abs(sin(irot*pi/180))*iext(1);
                end
                if quad2 || quad3; yoff_valign = 0; % top edge on bottom of textbox
                else; yoff_valign = abs(cos(irot*pi/180))*iext(2);
                end
            end
            % horizontal alignment considerations
            switch lower(ihalign);
            case 'left'
                if quad1 || quad4; xoff_halign = 0; % left edge on left-hand of textbox
                else; xoff_halign = abs(cos(irot*pi/180))*iext(1);
                end
                if quad1 || quad2; yoff_halign = 0; % left edge on bottom of textbox
                else; yoff_halign = abs(sin(irot*pi/180))*iext(2);
                end
            case 'center'
                xoff_halign = abs(cos(irot*pi/180))*iext(1)/2;
                yoff_halign = abs(sin(irot*pi/180))*iext(2)/2;
            case 'right'
                if quad2 || quad3; xoff_halign = 0; % left edge on left-hand of textbox
                else; xoff_halign = abs(cos(irot*pi/180))*iext(1);
                end
                if quad3 || quad4; yoff_halign = 0; % left edge on bottom of textbox
                else; yoff_halign = abs(sin(irot*pi/180))*iext(2);
                end
            end
            % raw length/height
            xlen = abs(cos(irot*pi/180))*iext(1) + abs(sin(irot*pi/180))*iext(2); % only sine matters when vertical, cosine when horizontal
            ylen = abs(cos(irot*pi/180))*iext(2) + abs(sin(irot*pi/180))*iext(1); % opposite
            % record extent
            absPos = [ipos(1) - xoff_halign - xoff_valign +  parPos(1) ...
                    ipos(2) - yoff_halign - yoff_valign + parPos(2) ...
                    xlen ylen];
            boxExtent(ii,:) = getOffsets(absPos, parPos);
                % "getOffsets" gets offset from parPos w.r.t. each edge
        end
        boxExtent = max(boxExtent, [], 1);
    case 'axes'
        %% Anchored axes objects (colorbars, etc.)
        % just get position relative to MAIN axis object
        set(ob,'Units','inches');
        pos = get(ob,'Position');
        margins = myget(ob,'Margin'); % should be initialized with [0 0 0 0] whenever we declare an axes
        absPos = [ipos(1)-margins(1) ipos(2)-margins(2) ...
                    ipos(3)+margins(1)+margins(3) ipos(4)+margins(2)+margins(4)];
        boxExtent = getOffsets(absPos, parPos);
    otherwise; error('mylocation:Input','Bad object type: %s',tp);
    end

function [ parPos, parMargin, writeMarginIDs ] = parentProperties( ob )
    % For GENERALIZED axes/text parents (figure or 2-axis), gets margin positions and "boxed" positions,
    % allowing for 2-axis anchoring, or figure edge anchoring.
    %% Parent position (recall parent can be 2-axis)
    par = myget(ob,'Parent'); % the "parent" used for anchoring/allocating margin space, not the actual parent
    parPos = myget(par,'Position'); parMargin = myget(par,'Margin');
    if iscell(parPos); parPos = cat(1,parPos{:}); parMargin = cat(1,parMargin{:}); end % remember parent can be 2-axis
    %% Adjustments ("effective" positions) for complex parent types
    npar = size(parPos,1);
    if strcmpi(tp,'figure');
        %% Adjust figure "position"
        parPos = [  parMargin(1) ... % x-start of non-margin space
                    parMargin(2) ... % y-start of non-margin space
                    parPos(3)-sum(parMargin([1 3])) ... % x-extent of non-margin space
                    parPos(4)-sum(parMargin([2 4]))]; % y-extent of non-margin space
    elseif npar==2
        %% Get "effective/combined" margins and position ffor two-axis parents
        % NOTE we can safely assume the side to which the object is anchored will be aligned, since flag would be raised where it is declared if not
        % NOTE also that for objects aligned in this way, they will ALWAYS be ordered left-to-right or bottom-to-top 
            % (e.g. if 2 axes side by side, we anchor legend to bottom, hpar will be [leftax rightax]); we will enforce this
        edge = myget(ob,'Edge');
        parPos = cat(1,parPos{:}); assert(size(parPos,2)==4,'Somthing weird happened; parent position array should be Nby4.');
        switch lower(edge(1))
        case 'w'
            parPos = [parPos(1,1) ... % {1} and {2} are same
                    parPos(1,2) ... % pick bottom axis
                    max(parPos(:,3)) ... % right-hand extent should not matter really, but try setting to max space
                    sum(parPos(:,4)) + (parPos(2,2)-(parPos(1,2)+parPos(1,4)))]; % upward extent; uses margin space
            parMargin = [parMargin(1,1) ... % are same
                    ... % NOTE ^^^ axis edges are aligned, but could current margins be different? NO because margins in subplot arrays are synced
                    parMargin(1,2) ... % bottom axis
                    max(parPos(:,3)+parMargin(:,3)) - max(parPos(:,3)) ... % robust
                    parMargin(2,4)]; % top axis
                % NOTE this may seem like overkill, but can be necessary for particular situation: two subplots above one major subplot, and we want
                % colorbar to left of all of them
        case 'e'
            parPos = [min(parPos(:,1)) ... % allows us to use the max below, since we know RHSs are lined up
                    parPos(1,2) ...
                    max(parPos(:,3)) ... % this will correctly identify RHS even if LHS margins don't line up; could also do max(LHSpos) and min(X-extent)
                    sum(parPos(:,4)) + (parPos(2,2)-(parPos(1,2)+parPos(1,4)))]; % upward extent; uses margin space
            parMargin = [min(parPos(:,1)) - min(parPos(:,1)-parMargin(:,1)) ... % robust
                    parMargin(1,2) parMargin(1,3) parMargin(2,4)]; % bottom axis; both the same; top axis
        case 's'
            parPos = [parPos(1,1) parPos(1,2) ...
                    sum(parPos(:,3)) + (parPos(2,1)-(parPos(1,1)+parPos(1,3))) ... % full extent left-through-right
                    max(parPos(:,4))]; % use maximum box width, but this doesn't really matter
            parMargin = [parMargin(1,1) parMargin(1,2) parMargin(2,3) ... % leftmost axis; both the same; rightmost axis
                    max(parPos(:,4)+parMargin(:,4)) - max(parPos(:,4))]; % robust
        case 'n'
            parPos = [parPos(1,1) ...
                    parPos(1,2) ...
                    parPos(1,3)+parPos(2,3) + (parPos(2,1)-(parPos(1,1)+parPos(1,3))) ... % full extent left-through-right
                    max(parPos(2,4),parPos(1,4))]; % use maximum box width, but this doesn't relaly matter
            parMargin = [parMargin(1,1) ... % leftmost axis
                    min(parPos(:,2)) - min(parPos(:,2)-parMargin(:,2)) ... % robust
                    parMargin(2,3) ... % rightmost axis
                    parMargin(1,4)]; % both the same
        end
    end
    %% Get ids for applying margin expansion
    % For 2-axis parents, when the new object position exceeds "box" position we must adjust each margin
    %writeMarginIDs = {1,1,1,1}; % default
    writeMarginIDs = [1 1 1 1];
    if npar==2;
        switch lower(edge(1))
        case {'w','e'}; writeMarginIDs = [1 1 1 2]; % north is the TOP (2nd) one
        case {'s','n'}; writeMarginIDs = [1 1 2 1];
        end
    end
%% MORE GENERALIZED option below (maybe should allow anchoring of multiple parents, or when user declares multi-parent anchor, sort them
%% automatically based on their positions and store only the 2 "edge" axes as parents
%%    if npar==2;
%%        switch lower(edge(1))
%%        case {'w','e'}; 
%%            %writeMarginIDs = {1:npar, 1, 1:npar, npar}; % W, S, E, N
%%                % NOTE for 2-axis anchored objects you should never be adding space to both left an right at same time
%%        case {'s','n'};
%%            %writeMarginIDs = {1, 1:npar, npar, 1:npar};
%%        end
%%    end

function [ keys ] = getKey( obs, parEdge )
    %% Gets priority "key" for object on specified side of axis.
    % Objects with no defined "key" will not have their positions reshuffled when they are generated by e.g. 
    % myticklabel, myylabel, etc. (objects with no key include insets, corner-anchored OUTSIDE legends, 
    % and outside text annotations)
    keys = zeros(1,length(obs));
    for iob=1:length(obs)
        % get tag
        chTag = get(obs(iob),'Tag');
        if strcmpi(chTag,'suptitle') || strcmpi(chTag,'title') || strcmpi(chTag,'abc')
            chTag = ['n' chTag];
        end
        % now main block
        switch lower(chTag)
        case [parEdge 'suptitle']; key = 6;
            % so for e.g. new object is west-aligned, wsuptitle will not occur
        case {[parEdge 'title'],[parEdge 'abc']}; key = 5;
        case [parEdge 'colorbar']; key = 4;
        case [parEdge 'panel']; key = 3;
        case [parEdge 'label']; key = 2;
        case {[parEdge 'ticklabel'],[parEdge 'multiplier'],'mlabel','plabel'}; key = 1;
        case [parEdge 'tick']; key = 0;
        otherwise; key = 999; % flag; will not adjust any positions based on these
        end
%% Obsolute: will now add objects incrementally AWAY from "non-margin" edge, then adjust the figure extent; simple!
%%        % REVERSE KEYS for figure-anchored objects (e.g. want suptitle CLOSER to edge than legend, etc.)
%%        partp = myget(obs(iob),'Parent');
%%        if ~iscell(partp); if strcmpi(partp,'figure'); key = 6-key; end; end
        % return key
        keys(iob) = key;
    end

function [ offsets ] = getOffsets( absPos, parPos, varargin );
    %% Gets 
    %% 1) if margins included in varargin, the EXTENT of object or object group with positions absPos beyond current margins (EXPANSION of margins required)
    %% 2) if margins not included, the EXTENT beyond axis box itself (this is RECORDED in object's UserData)
    if ~isempty(varargin); margins = varargin{1}; else; margins = [0 0 0 0]; end
    marginpos = [parPos(1)-margins(1) parPos(2)-margins(2) ... % left, bottom
                parPos(3)+margins(1)+margins(3) parPos(4)+margins(2)+margins(4)]; % extent right, up
    offsets(ii,1) = max(0,marginpos(1) - iabsPos(1));
    offsets(ii,2) = max(0,marginpos(2) - iabsPos(2));
    offsets(ii,3) = max(0,iabsPos(1)+iabsPos(3) - (marginpos(1)+marginpos(3)));
    offsets(ii,4) = max(0,iabsPos(2)+iabsPos(4) - (marginpos(2)+marginpos(4)));

