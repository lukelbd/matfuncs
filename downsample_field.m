function [ newfield ] = downsample_field( flons, flats, field, clons, clats );
    %% Actually a VERY TRICKY problem; looks complex, but necessary... although I think could rewrite
    %% this with geo_padarray 
    % This function downsamples data on spherical coordinates from a FINE resolution 
    % to COARSE resolution using area-weighted means. The motivation was 
    % it is bad practice to use bilinear, cubic, etc. interpolation 
    % schemes (even spherical versions) when reducing resolution, due to the associated loss
    % of information and blowing up of fine-scale sub-resolution features.
    % 
    % A *scattered* analogue to this function is "natural neighbor"
    % interpolation, which is similar to nearest neighbor, though assigns
    % weights to each neighboring gridpoint based on the proportional area
    % of cells belong to neighboring grid centers that go into forming the new polygon,
    % which has borders at the half-distances to neighboring cell centers. 
    %
    % Usage: downsample_field( field, flon, flat, clon, clat )
    %
    %   field is 1 data array with longitude on FIRST dimension,
    %       latitude on SECOND (i.e. rows are lons, columns are lats). can
    %       have higher dimensions as well; we will operate on each 2d instance
    %   flons and flats are 
    %       1) vectors for the "fine" grid (function infers borders)
    %       2) 1by2/2by1 cell arrays with centers and borders
    %   clons and clats are 
    %       1) vectors for the "coarse" grid (function infers borders)
    %       2) 1by2/2by1 cell arrays with centers and borders.
    %
    % The method in this file is just weighted cell averaging, and not
    % appropriate for grids of much smaller size (which would produce artifacts; needs smooothing). 
    % for coarse --> fine spherical, can indeed use "natural" for each query point, after identifying its
    % neighboring points (trivial in spherical coordinates) and converting
    % them to azimuthal equidistant projection coordinates with origin at query point; this would weight
    % polygons appropriately for distances on a spherical surface. If the grid were cartesian, bilinear
    % would be the equivalent (then the weights are exactly that of a linear interpolation in each direction); 
    % so perhaps we can justifiably continue with bilinear far away from poles. 
    %

    if nargin~=5; error('Incorrect input. Try help downsample_field for info.'); end

    %% Determine graticule ("borders" associated with the regular array of gridpoint centers).
    % fine lons
    if iscell(flons); flon = flons{1}(:); else; flon = flons(:); end
    flon = mod(flon, 360); [~,fshift] = min(flon); flon = circshift(flon, -fshift+1); 
    if iscell(flons)
        flonb = flons{1}(:); flonb = circshift(flonb, -fshift+1); % getvar.m should make identical borders
    else
        flonb = [flon(end)-360; flon; flon(1)+360]; flonb = (flonb(2:end)+flonb(1:end-1))/2; % leftmost and rightmost points match
    end
    flonb = flonb(1:end-1); % consider left edges only
    if flonb(1)<0; flonb = [flonb(2:end); flonb(1)+360]; flon = [flon(2:end); flon(1)+360]; fshift = fshift+1; end % leftmost left edge may now be less than zero; in that case, circshift one more
        % we now have vector of lon borders starting as close to prime meridian as possible
    flonb = [flonb; flonb(1)+360]; % now leftmost edge = rightmost edge - 360; circular

    % fine lats
    if iscell(flats); 
        flat = flats{1}(:); flatb = flats{1}(:);
    else
        flat = flats(:);
        flatb = [-90; (flat(2:end)+flat(1:end-1))/2; 90];
        if flatb(1)==flat(1); flat(1) = sum(flatb(1:2))/2; end
        if flatb(end)==flat(end); flat(end) = sum(flatb(end-1:end))/2; end
    end

    % double check
    if length(flons)~=size(field,1) || length(flats)~=size(field,2); error('Field dimensions do not match longitude/latitude sizes.'); end

    % coarse lons
    if iscell(clons); clon = clons{1}(:); else; clon = clons(:); end
    clon = mod(clon, 360); [~,cshift] = min(clon); clon = circshift(clon, -cshift+1);
    if iscell(clons)
        clonb = clons{1}(:); clonb = circshift(clonb, -cshift+1);
    else
        clonb = [clon(end)-360; clon; clon(1)+360]; clonb = (clonb(2:end)+clonb(1:end-1))/2; 
    end
    clonb = clonb(1:end-1);
    if clonb(1)<0; clonb = [clonb(2:end); clonb(1)+360]; clon = [clon(2:end); clon(1)+360]; cshift = cshift+1; end % fix so that new leftmost edge is zero
    clonb = [clonb; clonb(1)+360]; % now leftmost edge = rightmost edge - 360; circular

    % coarse lats
    if iscell(clats);
        clat = clats{1}(:); clatb = clats{1}(:);
    else
        clat = clats(:);
        clatb = [-90; (clat(2:end)+clat(1:end-1))/2; 90];
        if clatb(1)==clat(1); clat(1) = sum(clatb(1:2))/2; end
        if clatb(end)==clat(end); clat(end) = sum(clatb(end-1:end))/2; end
    end
    nclon = length(clon); nclat = length(clat);
        % grids should already be circshifted in longitude to match

    % extend flonb
    padnume = 0; padnums = 0;
    if clonb(1)>flonb(1); % note position "1" and "end" are identical mod 360.
        padnume = find(flonb>=clonb(1),1,'first')-1; % e.g. if fist clonbs are [1.5 3 4.5] and first flonbs are [.5 1.5 2.5], find will return ID==(2) 
        % and we will want to pad ONE right-hand edge on END of flonb vector. we pad ID=(2)-1 = 1, usng locations 2:ID
    end
    if clonb(1)<flonb(1) % and thus, the same on RH edge
        padnums = length(flonb)-find(flonb<=clonb(end),1,'last'); % e.g. if last clonbs are [356 358.5 361] and last flonbs are [357.5 359.5 361.5], find will return ID==(end-1) 
        % and we want to pad ONE left-hand edge (359.5) on START of flonb vector. we pad length()-(ID==length()-1) = 1, using location ID:end-1
    end
    newflonb = [flonb; flonb(2:padnume+1)+360]; % add new right-hand edges (and, preserve montonicity)
    newflon = [flon; flon(1:padnume)+360]; % doesn't really matter
    newflonb = [flonb(end-padnums:end-1)-360; newflonb];
    newflon = [flon(end-padnums+1:end)-360; newflon];
    flon = newflon; flonb = newflonb;
    
    %fprintf('Coarse:\n'); disp(clon([1:5 end-4:end])'), disp(clonb([1:5 end-4:end])')
    %fprintf('Fine:\n'); disp(flon([1:5 end-4:end])'), disp(flonb([1:5 end-4:end])') %, flonb', clatb', flatb' %flon', clon', flonb', clonb'a
    %fprintf('Lats:\n'); disp(clatb([1:5 end-4:end])'), disp(flatb([1:5 end-4:end])')

    %% Downsample
    fsize = size(field); reshapelen = prod(fsize(3:end)); % returns 1 if empty, i.e. if field is 2-dimensional
    field = reshape(field,[fsize(1:2) reshapelen]);
    field = circshift(field,[-fshift+1 0 0]); %field = padarray(field,[padnume 0],'post','circular');
    newfield = NaN(nclon, nclat, reshapelen);
    for z=1:reshapelen
        fprintf('Level %d, ',z);
        ifield = field(:,:,z); ifield = [ifield(end-padnums+1:end,:); ifield; ifield(1:padnume,:)];
        for ilat=1:nclat; for ilon=1:nclon;
            % fine graticule edges entirely encompassed by coarse cell at ilon, ilat
            iclonb = clonb(ilon:ilon+1); iclatb = clatb(ilat:ilat+1);
            lonslice = find(flonb<=iclonb(2) & flonb>=iclonb(1)); % will be vertical 
            latslice = find(flatb<=iclatb(2) & flatb>=iclatb(1)); % these are
                % the "boxes" entirely within coarse grid boundaries
            lonbox = flonb(lonslice); latbox = flatb(latslice);
                % grid boxes corresponding to the borders

            % field box; account for fine cells *partially* within coarse cell borders
            fieldbox = ifield(lonslice(1:end-1),latslice(1:end-1)); newlatslice = latslice;
            if latbox(1)~=iclatb(1); latbox = [iclatb(1); latbox]; fieldbox = [ifield(lonslice(1:end-1),latslice(1)-1) fieldbox]; newlatslice = [latslice(1)-1; newlatslice]; end
            if latbox(end)~=iclatb(2); latbox = [latbox; iclatb(2)]; fieldbox = [fieldbox ifield(lonslice(1:end-1),latslice(end))]; newlatslice = [newlatslice; latslice(end)+1]; end  
            if lonbox(1)~=iclonb(1); lonbox = [iclonb(1); lonbox]; fieldbox = [ifield(lonslice(1)-1,newlatslice(1:end-1)); fieldbox]; end
            if lonbox(end)~=iclonb(2); lonbox = [lonbox; iclonb(2)]; fieldbox = [fieldbox; ifield(lonslice(end),newlatslice(1:end-1))]; end
                % RH edges are ids of box

            % get weighted average
%            %% NOTE: old version had incorrect weights! refer to my derivation,
%            %% in ~/Dropbox/Quick Reference/weighting.pdf
            box_sizes = (diff(lonbox)*pi/180)*diff(sin(latbox'*pi/180)); % lon by lat array of relative cell areas
%            box_sizes = (diff(lonbox)*pi/180) ...
%             * ... % creates lon by lat array (column times row matrix mult)
%             (sin((diff(latbox)'/2)*pi/180).*cos(((latbox(1:end-1)'+latbox(2:end)')/2)*pi/180));
            newfield(ilon,ilat,z) = sum(sum(box_sizes.*fieldbox))/sum(box_sizes(:)); % normalized
            %latbox, lonbox, fieldbox, newfield(ilon,ilat,z), pause(5)
        end; end
    end
    fprintf('\n');

    % Reshape grid, re-order longitudes
    newfield = circshift(newfield,[cshift-1 0 0]); % back to original order
    newfield = reshape(newfield, [nclon nclat fsize(3:end)]); % original size
end
