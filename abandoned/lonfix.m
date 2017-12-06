function [newlon] = lonfix(lon);
% Fixes longitudes for display purposes. Trivial, but useful.
%
    lon = mod(lon,360); 
    filt = lon>180;
    lon(filt) = lon(filt)-360;
    newlon = lon;
end
