function [ h ] = myplot( ax, x, y )
    % Plots objects with optional default settings, and using underlying marker sizes/line sizes 
    % specified by figure UserData.
    %
    % Will delegate clipping, etc. according to primary/secondary axes settings; line is separated into marker/line
    % components (projection or not)
    %
    % TODO/NOTE should make ALL functions compatible with both REGULAR and MAP-type axes; the projection will be implicit; only 
    % takes place if axes has "projection" property, and can be done easily; just proceed like normal, then warp coordinates
    % at the end onto projection coordinates.
