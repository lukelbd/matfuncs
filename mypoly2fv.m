function [ F, V, xs, ys ] = mypoly2fv( xs, ys );
    % Converts array-indexed (separator is row of NaNs) or cell-array-indexed (each polygon x, y indices are self contained in 1by1 cells of vectors)
    % set of polygons to Face-Value format with HOLES where one object is inside another, etc.    
    
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
        if mod(n_circum_ctours,2)==1
            [xnew, ynew] = poly2ccw(xs{pid},ys{pid});
        else
            [xnew, ynew] = poly2cw(xs{pid},ys{pid});
        end
        xs{pid} = xnew; ys{pid} = ynew; % note that "inpolygon" is indifferent to vertex ordering.
    end
    [F, V] = poly2fv(xs, ys);

end
