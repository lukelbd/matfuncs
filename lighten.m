function [ c ] = lighten( c, fact )
    % Outputs new, pale version of colors (any format, e.g. Nby3, xbyyby3, etc.) with no blowouts
    % See screen filter in Photoshop:
    % http://photoblogstop.com/photoshop/photoshop-blend-modes-explained
    assert(nargin>0 && nargin<3,'Must have only 1 or two input args.');
    if exist('fact')~=1; fact = 0.5; end
    assert(isscalar(fact),'Factor must be scalar.');
    assert(fact>=0 && fact<=1,'Factor must be between 0 and 1.');
    c = 1-(1-fact)*(1-c); % screen; assymptotically approaches white as fact-->1
%    c = c/(1-fact); % this is a color dodge, and CAN be blown out
