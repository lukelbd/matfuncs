function [ rgb ] = hex2rgb(hex,range)
% hex2rgb converts hex color values to rgb arrays on the range 0 to 1. 
% hex can be cell-vector of hex codes, or a single string
% SYNTAX:
% rgb = hex2rgb(hex) returns rgb color values in an n x 3 array. Values are
%                    scaled from 0 to 1 by default. 
% rgb = hex2rgb(hex,256) returns RGB values scaled from 0 to 255. 
% 

%% Input checks:
assert(nargin>0&nargin<3,'hex2rgb function must have one or two inputs.') 
if nargin==2
    assert(isscalar(range)==1,'Range must be a scalar, either "1" to scale from 0 to 1 or "256" to scale from 0 to 255.')
end

%% Tweak inputs if necessary: 
if iscell(hex)
    assert(isvector(hex)==1,'Unexpected dimensions of input hex values.')
    hex = hex(:); % force columns
    hex = cell2mat(hex); % convert to matrix
end

if strcmpi(hex(1,1),'#')
    hex(:,1) = [];
end
if nargin == 1
    range = 1; 
end

%% Convert from hex to rgb: 
switch range
case 1
    rgb = reshape(sscanf(hex.','%2x'),3,[]).'/255;
case {255,256}
    rgb = reshape(sscanf(hex.','%2x'),3,[]).';
otherwise
    error('Range must be either "1" to scale from 0 to 1 or "256" to scale from 0 to 255.')
end

end

