function [ F, V, xs, ys ] = mypoly2fv( xs, ys );
    % Converts array-indexed (separator is row of NaNs) or cell-array-indexed (each polygon x, y indices 
    % are self contained in 1by1 cells of vectors) set of polygons to Face-Value format with HOLES where 
    % one object is inside another, etc.
    %
    % Usage: [ F, V, xs, ys ] = mypoly2fv( xs, ys );
    %
    % Input:
    %   xs, ys - Array-indexed (separator is row of NaNs) or cell-array index (each polygon x, y indices 
    %               are self contained in 1by1 cells of vectors) vertices
    %
    % Output:
    %   F - Faces
    %   V - Vertices
    %   xs - Counterclockwise/clockwise adjusted x vertices, CELL format
    %   ys - Counterclockwise/clockwise adjusted y vertices, CELL format
    %
    % When drawing objects, must make TWO: use F, V fo INTERIOR colors, etc., with 'LineStyle','none'
    % and use xs, ys for EDGES with 'FaceColor','none'. This allows both for holes within objects, AND edges;
    % if you try to draw edges with F-V, lines will criss-cross across object randomly (vertices are not
    % sequential in this format, in order to allow for holes by "stitching" across solid parts)
    %
    % Useful if your vertices are not auto sorted clockwise/counterclockwise corresponding to solid vs. "hole" status;
    % e.g. Matlab's coast.mat file coastlines are oriented randomly; MUST apply this for lakes to appear transparent if
    % we want to color land solid, e.g.
    
    % Input
    if ~iscell(xs) && ~iscell(ys)
        [xs, ys] = polysplit(xs, ys); % converts NaN-separated individual polygons to cell indexing
    elseif ~(iscell(xs) && iscell(ys))
        error('Bad input.');
    end
    [xs, ys] = poly2cw(xs, ys);

    % Errors
    flag = false;
    if length(xs)~=length(ys);
        flag = true;
    elseif any(cellfun(@length,xs)~=cellfun(@length,ys)); 
        flag = true;
    end
    if flag; error('Different number of patch X-indices and patch Y-indices.'); end

    % Get Face-values
    npids = length(xs);
    for pid=1:npids
        n_circum_ctours = 0;
        for pid_outer=[1:(pid-1) (pid+1):npids]
            if all(inpolygon(xs{pid},ys{pid},xs{pid_outer},ys{pid_outer}));
                n_circum_ctours = n_circum_ctours+1; break; % all vertices of one closed contour are contained in another; it is "interior"
            end
        end
        if mod(n_circum_ctours,2)==1 % allows for e.g. shapes INSIDE a hole, etc.
            [xnew, ynew] = poly2ccw(xs{pid},ys{pid});
        else
            [xnew, ynew] = poly2cw(xs{pid},ys{pid});
        end
        xs{pid} = xnew; ys{pid} = ynew; % note that "inpolygon" is indifferent to vertex ordering.
    end
    [F, V] = poly2fv(xs, ys);

end
