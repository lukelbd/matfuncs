function [ h ] = marginfix( ax, marginAdds, varargin )
    % Function called by objectfix after an expansion of axes margins is requested.
    % Also writes new "margins" to file after figure

    %% Parse input, initial stuff
    % get "writeflag" -- whether we record this margin expansion in axes metadata, or leave it untouched so that
    % no objects will be allowed to occupy that space
    ax = ax(:);
    assert(length(varargin)<=3,'Too many input args.');
    writeflag = true; recurseCount = 0; prefix = '';
    for iarg=1:length(varargin)
        arg = varargin{iarg};
        if ischar(arg)
            switch lower(arg)
            case 'nowrite'; writeflag = false;
            case 'write'; writeflag = true; % or just leave default
            otherwise; prefix = arg;
            end
        elseif isnumeric(arg)
            recurseCount = arg;
        else; error('Bad input argument.');
        end
    end
    % show figures?
    show = true;
    if recurseCount>0; show = false; end % try not showing the inner-developments
    % break off recursion
    if recurseCount>5; 
        error(['Marginfix recursed >5 times while applying row/column aspect-ratio preservation. This is probably due to multiple vertical/horizontal intersections by margins of the same spanning axes.' ...
                'Consider changing subplot type or aspect ratio-preserving action.']);
    end

    for iax=1:length(ax) % do the same for each parent
        %% Get properties
        % figure stuff
        figflag = false;
        axtp = get(ax(iax),'Type');
        if strcmpi(axtp,'figure')
            f = ax(iax); figflag = true;
        elseif strcmpi(axtp,'axes')
            % make sure it is a MAIN axis
            axtag = get(ax(iax),'Tag');
            assert(~isnan(str2double(axtag)),'Axis for margin modification is not a MAIN axis.');
            % figure
            f = myget(ax(iax),'Parent'); % NOTE both ax should have same parent
        else; error('Bad handle type for margin modification: %s',axtp);
        end
        set(f,'Visible','off'); % turn "Visible" OFF while we push around the various axes
        % main
        handleArray = myget(f,'HandleArray');
        ncol = size(handleArray,2); nrow = size(handleArray,1);
        rowWidths = myget(f,'RowWidths'); colWidths = myget(f,'ColWidths');
        % other stuff
        HoldX = myget(f,'HoldX'); HoldY = myget(f,'HoldY');
        HoldAR = myget(f,'HoldAR');
        FixStretch = myget(f,'FixStretch');
        %% Adjust positions of subplots/axes
        for id=1:4; if marginAdds(iax,id)>0 % IF THERE IS SOMETHING TO ADD, add it
            % margin stuff
            marginWidth = marginAdds(iax,id);
            marginAdd = [0 0 0 0]; marginAdd(id) = marginAdds(iax,id); % offset factor
            [y,x] = find(handleArray==ax(iax));
            if figflag;
                %% BYPASS for figure margins; this is very simple (we just move everything and write the margin)
                if id==1 || id==2 % West/South locations (then have to move positions of everything else); NOTE re-anchoring by anchor.m will fix everything
                    hs = unique(handleArray(:));
                    for ih=1:numel(hs)
                        MODIFY(hs(ih),'Position',marginAdd);
                    end
if show; myprint(f,['./' prefix 'rowcol' num2str(y(1)*10+x(1)) '-subrowcol00' '-margin' num2str(id) '-beforeafter1' '-subsubrowcol00part0-recur' num2str(recurseCount)],'noeps'); end
                end
                MODIFY(f,'Margin',marginAdds);
            else
                %% Filters for where to move/stretch/apply margins
                switch id
                case 1
                    y = max(y); x = min(x);
                    moveFilt = x; marginFilt = x; stretchFilt = [x-1 x]; % x for id==1, x+1 for id==3; for WEST, start at x (left); for EAST, start at x+1 (right)
                case 2
                    y = max(y); x = min(x);
                    moveFilt = y; marginFilt = y; stretchFilt = [y y+1]; % y for id==2, y-1 for id==4; for SOUTH, start at y (below); for NORTH, start at y-1 (above)
                case 3
                    y = max(y); x = max(x);
                    moveFilt = x+1; marginFilt = x; stretchFilt = [x x+1];
                case 4
                    y = min(y); x = min(x);
                    moveFilt = y-1; marginFilt = y; stretchFilt = [y-1 y];
                end
                y = max(y); x = min(x);
                %% Write margins and move/stretch axes to accomadate space
                % Unfortunately this block has to be something of a monstrosity; it may be tweaked in future but the comments
                % are detailed enought that you should be able to figure out what's going on
                if id==2 || id==4;
                    %% Loop through each axis in handleArray
                    moveAdd = [0 marginAdds(iax,id) 0 0];
                    stretchAdd = [0 0 0 marginAdds(iax,id)];
                    for irow=1:nrow; for icol=1:ncol
                        ih = handleArray(irow,icol);
                        % x/y locations of handle at location (row,column)
                        [iy,ix] = find(handleArray==ih);
                        if icol==ix(1) && irow==iy(1) % if not, we have applied these operations somewhere else in loop
                        if any(iy==stretchFilt(1)) && any(iy==stretchFilt(2)); 
                            %% Y-stretch and compensate in X-direction if necessary
                            % apply
                            MODIFY(ih,'Position',stretchAdd); 
                            % fix stretch (preserves AR of column(s) in which axis was vertically stretched)
                            HoldAR, FixStretch
                            if HoldAR && FixStretch 
                                marginWidthCompensate = marginWidth*sum(colWidths(unique(ix)))/sum(rowWidths); % scaled by "aspect-ratio" of COLUMN axes objects
                                colWidthsAdd = zeros(ncol,1); colWidthsAdd(unique(ix)) = marginWidthCompensate*colWidths(unique(ix))/sum(colWidths(unique(ix))); % distribute equally
                                MODIFY(f,'ColWidths',colWidthsAdd);
                                ixloop = (unique(ix(:))');
                                for jcol=ixloop; colHasRightEdge = 0;
                                    for jrow=1:nrow % loop through the columns to be broadened (usually just 1, NOTE)
                                        jh = handleArray(jrow,jcol);
                                        [jy,jx] = find(handleArray==jh);
                                        % manually stretch horizontally (if we are at axis RIGHT EDGE)
                                        if jcol==max(jx) && jy(1)==jrow; % when maximum eastward extent of axes hits one of the columns for which an East margin will be added
                                            jstretchAdd = [0 0 colWidthsAdd(jcol) 0];
                                            MODIFY(jh,'Position',jstretchAdd); % remember; this is an EXTENSION here
if show; myprint(f,['./' prefix 'rowcol' num2str(y(1)*10+x(1)) '-subrowcol' num2str(irow*10+icol)  '-margin' num2str(id) '-beforeafter0' '-subsubrowcol' num2str(jrow*10+jcol) 'part0-recur' num2str(recurseCount)],'noeps'); end
                                            colHasRightEdge = jcol; axpick = jh;
                                        end
                                    end
                                    % and call marginfix to adjust everything else; works because this compensating stretch is JUST LIKE inserting margin-space; except here, we've actually inserted axis-space
                                    if colHasRightEdge~=0; % only need to do this ONCE for the ENTIRE ROW at the END OF LOOP
newprefix = [prefix 'rowcol' num2str(y(1)*10+x(1)) '-subrowcol' num2str(irow*10+icol)  '-margin' num2str(id) '-beforeafter0' '-subsubrowcol' num2str(jrow*10+jcol) 'part2-recur' num2str(recurseCount)];
                                        marginfix(axpick,jstretchAdd,'nowrite',recurseCount+1,newprefix); % we added (effectively) an EAST MARGIN
                                            % use 'nowrite' because we aren't REALLY changing margin here; just stretching axes
                                    end
                                end
                                rowWidths = myget(f,'RowWidths'); % might be further changed by stretch/add
                                colWidths = myget(f,'ColWidths');
                            end
                        else % current axis does not vertically span the margin-space
                            %% Y-move and/or write N/S margins
                            % write new margins (if in appopriate location)
                            if any(iy==marginFilt) && writeflag % use "any" since it doesn't span margin-space (if it occupies the add-margin row, can add it there) write margin 
                                MODIFY(ih,'Margin',marginAdd);
                            end
                            % move (if in appropriate location)
                            if max(iy)<=moveFilt % move axis (e.g. for South margin, move axes aboe and INCLUDING current row; for North, just those above)
                                MODIFY(ih,'Position',moveAdd);
if show; myprint(f,['./' prefix 'rowcol' num2str(y(1)*10+x(1)) '-subrowcol' num2str(irow*10+icol)  '-margin' num2str(id) '-beforeafter1' '-subsubrowcol00part0-recur' num2str(recurseCount)],'noeps'); end
                            end
                        end
                        end % icol and irow selection
                    end; end
                elseif id==1 || id==3
                    %% Loop through each axis in handleArray
                    moveAdd = [marginAdds(iax,id) 0 0 0];
                    stretchAdd = [0 0 marginAdds(iax,id) 0];
                    for irow=1:nrow; for icol=1:ncol
                        ih = handleArray(irow,icol);
                        % x/y locations of handle at location (row,column)
                        [iy,ix] = find(handleArray==ih);
                        if icol==ix(1) && irow==iy(1) % if not, we have applied these operations somewhere else in loop
                        if any(ix==stretchFilt(1)) && any(ix==stretchFilt(2)); 
                            %% X-stretch and compensate in X-direction if necessary
                            % apply horizontal stretch
                            MODIFY(ih,'Position',stretchAdd);
                            % fix by applying vertical stretch (preserves AR of entire row(s) in which axis was horizontally stretched)
                            if HoldAR && FixStretch
                                marginWidthCompensate = marginWidth*sum(rowWidths(unique(iy)))/sum(colWidths); % scaled by "aspect-ratio" of COLUMN axes objects
                                rowWidthsAdd = zeros(nrow,1); rowWidthsAdd(unique(iy)) = marginWidthCompensate*rowWidths(unique(iy))/sum(rowWidths(unique(iy)));
                                MODIFY(f,'RowWidths',rowWidthsAdd);
                                iyloop = (unique(iy(:))');
                                for jrow=iyloop; rowHasTop = 0;
                                    for jcol=1:ncol; % loop through only rows to be broadened (EXAMPLE: if apply East margin to plot #1, subplot [1 2; 3 3; 3 3], need to 
                                            % expand both row 2 AND row 3); usually just 1, NOTE
                                        jh = handleArray(jrow,jcol);
                                        [jy,jx] = find(handleArray==jh);
                                        % manually stretch entire row vertically, if axis TOP EDGE falls here
                                        if jrow==min(jy) && jx(1)==jcol; % jrow means jx(1)==jcol part is so we don't do this twice
                                            jstretchAdd = [0 0 0 rowWidthsAdd(jrow)];
                                            MODIFY(jh,'Position',jstretchAdd); % remember; this is an EXTENSION here
if show; myprint(f,['./' prefix 'rowcol' num2str(y(1)*10+x(1)) '-subrowcol' num2str(irow*10+icol) '-margin' num2str(id) '-beforeafter0' '-subsubrowcol' num2str(jrow*10+jcol) 'part2-recur' num2str(recurseCount)],'noeps'); end
                                            rowHasTop = 1; axpick = jh;
                                        end
                                    end
                                    % and call marginfix to adjust everything else; works because this compensating stretch is JUST LIKE inserting margin-space; except here, we've actually inserted axis-space
                                    if rowHasTop~=0 % else, have handleArray of e.g. [1 2; 3 3; 3 3]
newprefix = [prefix 'rowcol' num2str(y(1)*10+x(1)) '-subrowcol' num2str(irow*10+icol) '-margin' num2str(id) '-beforeafter0' '-subsubrowcol' num2str(jrow*10+jcol) 'part2-recur' num2str(recurseCount)];
                                        marginfix(axpick,jstretchAdd,'nowrite',recurseCount+1,newprefix); % we added (effectively) an EAST MARGIN
                                    end
                                end
                                rowWidths = myget(f,'RowWidths'); % might be further changed by stretch/add
                                colWidths = myget(f,'ColWidths');
                            end
                        else % current axis does not horizontally  span the margin-space
                            %% X-move and/or write N/S margins
                            % write new margins (if in appopriate location)
                            if any(ix==marginFilt) && writeflag % use "any" since it doesn't span margin-space (if it occupies the add-margin row, can add it there) write margin 
                                    % NOTE writeflag can be enabled 
                                MODIFY(ih,'Margin',marginAdd);
                            end
                            % move (if in appropriate location)
                            if min(ix)>=moveFilt % move axis (e.g. for South margin, move axes aboe and INCLUDING current row; for North, just those above)
                                MODIFY(ih,'Position',moveAdd);
if show; myprint(f,['./' prefix 'rowcol' num2str(y(1)*10+x(1)) '-subrowcol' num2str(irow*10+icol) '-margin' num2str(id) '-beforeafter1' '-subsubrowcol00part0-recur' num2str(recurseCount)],'noeps'); end
                            end
                        end
                        end % icol and irow selection
                    end; end
                end
            end

            %% Modify figure, axes, and/or both in light of allocation of extra margin space
            if (~HoldX && mod(id,2)==1) || (~HoldY && mod(id,2)==0)
                %% Just modify figure extent (also preserves AR automatically since we aren't squashing axes)
                MODIFY(f,'Position',stretchAdd); % the same we would have applied to axes
            else
                %% Distribute margin space allocation by shrinking row/column widths (and if HoldAR==1, correspondingly shrinking column/row widths)
                % determine (row,column) locations for sampling left-hand sides and right-hand sides for getting zones
                % this is hard to visualize, but e.g. for supplot array [1 1 2; 3 4 4] can't just go along each row
                hlist = unique(handleArray(:));
                if id==2 || id==4
                    % row width factors (DISTRIBUTES squeeze due to margin space allocation in proportioan to row widths)
                    rowWidthsSubtract = rowWidths*marginWidth/sum(rowWidths);
                    % aspect ratios
                    if HoldAR
                        marginWidthCompensate = marginWidth*sum(colWidths)/sum(rowWidths);
                        colWidthsSubtract = colWidths*marginWidthCompensate/sum(colWidths);
                    else
                        colWidthsSubtract = zeros(ncol,1);
                    end
                elseif id==1 || id==3
                    % col width factors
                    colWidthsSubtract = colWidths*marginAdd(id)/sum(colWidths);
                        % ^^^NOTE this DISTRIBUTES squeeze due to margin space proportional to axes heights
                    % aspect ratios
                    if HoldAR
                        marginWidthCompensate = marginWidth*sum(rowWidths)/sum(colWidths);
                        rowWidthsSubtract = rowWidths*marginWidthCompensate/sum(rowWidths);
                    else
                        rowWidthsSubtract = zeros(nrow,1);
                    end
                end
                % modify (move+stretch)
                for ih=1:length(hlist)
                    [idown,iacross] = find(handleArray==hlist(ih));
                    movestretchAdd = [ -sum(colWidthsSubtract(1:min(iacross)-1)) ... % LH edge
                                    -sum(rowWidthsSubtract(max(idown)+1:end)) ... % Bottom edge
                                    -sum(colWidthsSubtract(unique(iacross))) ... % X extent (NOTE that iacross can be multi-dim); unique necessary because e.g. if a=1, sum(a([1 1]))==2
                                    -sum(rowWidthsSubtract(unique(idown)))]; % Y extent
                    MODIFY(hlist(ih),'Position',movestretchAdd);
                end
                % reset widths/heights
                MODIFY(f,'RowWidths',-1*rowWidthsSubtract);
                MODIFY(f,'ColWidths',-1*colWidthsSubtract);

                %% Re-anchor 
                % NOTE for axes-type objects, if there was re-shuffling, 
                ch = myget(hlist,'Children'); if ~iscell(ch); ch = {ch}; end
                ch = cellfun(@(x)x(:),ch,'UniformOutput',false); ch = cat(1,ch{:});
                tp = get(ch,'Type'); axFilt = cellfun(@(x)strcmpi(x,'axes'),tp);
                axch = find(axchFilt);
                for ii=1:length(ch)
                    ich = ch(ii);
                    if axFilt;
                        anchor(ah); % anchor is designed for AXES objects
                    else
                        % special operation for TEXT objects... OR GENERALIZE anchor for text objects...
                        % OR (FINAL SOLUTION I THINK) just set units to be RELATIVE/NORMALIZED for most external text objects, and Data for ticklabels.
                        % ...but then that messes up e.g. a two-axis spanning supertitle... but does that even exist? maybe should make the spanning-text labels
                        % into AXES objects; otherwise have to generalize task of text-repositioning. SO! I will commit to make multiple axis-spanning or figure-spanning
                        % text objects as invisible axes
                    end
                end
            end
if show; myprint(f,['./' prefix 'rowcol' num2str(y(1)*10+x(1)) '-subrowcol' num2str(irow*10+icol) '-margin' num2str(id) '-beforeafter3' '-subsubrowcol00part0-recur' num2str(recurseCount)],'noeps'); end
        end; end
    end

    %% Turn figure back on
    set(f,'Visible','on');
    % And we're done! wasn't that easy? .....

function [] = MODIFY(h, name, offset);
    % General function for modifying position and margin (SUPER IMPORTANT)
    val = myget(h, name);
    myset(h, name, val+offset);

