function [ c ] = darken( c, fact )
    % Outputs new, dark version of colors (any format, e.g. Nby3, xbyyby3, etc.) with no blowouts
    % See multiply filter in Photoshop:
    % http://photoblogstop.com/photoshop/photoshop-blend-modes-explained
    assert(nargin>0 && nargin<3,'Must have only 1 or two input args.');
    if exist('fact')~=1; fact = 0.5; end
    assert(isscalar(fact),'Factor must be scalar.');
    assert(fact>=0 && fact<=1,'Factor must be between 0 and 1.');
    c = (1-fact)*c; % multiply; assymptotically approaches black as fact-->1
%    c = c/(1-fact); % this is a color dodge, and CAN be blown out
