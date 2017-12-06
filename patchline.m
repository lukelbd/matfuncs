function p = patchline(xs,ys,varargin)
% Plot lines as patches (efficiently)
%
% SYNTAX:
%     patchline(xs,ys)
%     patchline(xs,ys,zs,...)
%     patchline(xs,ys,zs,'PropertyName',propertyvalue,...)
%     p = patchline(...)
%
% PROPERTIES: 
%     Accepts all parameter-values accepted by PATCH.
% 
% DESCRIPTION:
%     p = patchline(xs,ys,zs,'PropertyName',propertyvalue,...)
%         Takes a vector of x-values (xs) and a same-sized
%         vector of y-values (ys). z-values (zs) are
%         supported, but optional; if specified, zs must
%         occupy the third input position. Takes all P-V
%         pairs supported by PATCH. Returns in p the handle
%         to the resulting patch object.

[zs,PVs] = parseInputs(varargin{:});
if rem(numel(PVs),2) ~= 0
    % Odd number of inputs!
    error('patchline: Parameter-Values must be entered in valid pairs')
end

% Facecolor = 'k' is (essentially) ignored here, but syntactically necessary
if isempty(zs)
    p = patch([xs(:);NaN],[ys(:);NaN],'k');
else
    p = patch([xs(:);NaN],[ys(:);NaN],[zs(:);NaN],'k');
end

% Apply PV pairs
for ii = 1:2:numel(PVs)
    set(p,PVs{ii},PVs{ii+1})
end
if nargout == 0
    clear p
end

function [zs,PVs] = parseInputs(varargin)
if isempty(varargin)
    zs = [];
    PVs = {};
else
    if isnumeric(varargin{1})
        zs = varargin{1};
        PVs = varargin(2:end);
    else
        PVs = varargin;
        zs = [];
    end
end
