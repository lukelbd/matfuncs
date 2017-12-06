function [ nfield ] = upsample_field(field, method, lons, lats, qlons, qlats);
    % This function interpolates data on spherical coordinates. special considerations have to be 
    % made around the edges. No extrapolation is allowed outside convex domain of data grid. 
    % We avoid making a column of NaNs by circularly shifting the grids until two meridians 
    % from the fine grid are enclosed within or lie upon two meridians from the coarse grid,
    % then circularly shifting back.
    %
    % Usage: interp_var({data_fine, data_coarse}, interp_method, ...
    %                   fine_longrid, fine_latgrid, coarse_longrid, coarse_latgrid)
    %
    %   field is data array with longitude on FIRST dimension,
    %       latitude on SECOND (i.e. rows are lons, columns are lats)
    %   method is interpolation type. right now, just use "linear" or
    %       "nearest." For seamless interpolation with cubic or spline, need to
    %       pad by more than one column (this function just uses one).
    %   lons and lats are the meshgrids, scattered points, OR vectors for longitude/latitude
    %       indexing associated with current data. 
    %   qlons and qlats are the meshgrids, scattered points, OR vectors for 
    %       query points. 
    %
    %   Matlab's available interpolation procedures can be seen (for
    %   regular/gridded data) in griddedInterpolant documentation, and (for scattered data)
    %   in scatteredInterpolant documentation. For 2-D data, they are respectively,
    %   <'linear','nearest','cubic','spline'> and <'linear','nearest','natural'>
    %   Note that scattered linear is different from gridded linear; whereas
    %   gridded is just 1d linear in 2 directions, scattered constructs
    %   Delaunay triangulations and interpolates between the vertices. Make
    %   sure you input grids generated with meshgrid, and rows/columns are
    %   exaclty equal -- or input the vectors, and it is done here.
    %
    %   For scattered data, should consider using more sophisticated
    %   schemes like Cressman weighting, Barnes weighting, Lanczos resampling,
    %   or Kriging. See wiki page on multivariate interpolation. But, natural
    %   is pretty good.
    %
    %   Also consider spherical harmonics of course, when cells are big or
    %   near the poles.
    %
    %   ***PUT THIS IN A BOX, AND DON'T THINK ABOUT IT. MAYBE DO IT NEXT
    %   YEAR. DON'T NEED TO UPSAMPLE FOR RESEARCH; CAN JUST ALWAYS DOWNSAMPLE. 
    %   TALK TO TIM OR YI ABOUT IT FIRST; MAYBE THEY THINK IT'S DUMB.***
    %

    % Make meshgrid
    if isvector(lons) && isvector(lats);
        [latgrid, longrid] = meshgrid(lats, lons); % column labels, row labels
    else; longrid = lons; latgrid = lats;
    end
    if isvector(qlong) && isvector(qlats);
        [qlatgrid, qlongrid] = meshgrid(qlats, qlons); 
    end

    % Get neighboring points for each query point

    % Get eqdazim coordinates; preserves orientation and great circle
    % distances

    % Apply scheme; can use "natural" method, or custom Cressman/Barnes
    % interpolation. Natural method would be nice extension of
    % downsample_field.m; basically is same thing, with extra smoothing.

    % Output

end
