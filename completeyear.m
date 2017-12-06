function [ tnew, dnew ] = completeyear(t, d, dim, option);
    % Adjusts data to be composed only of COMPLETE YEARS.
    % Can optionally make 'years' start on preceding december to november, representing
    % a more typical composition of the 4 seasons (DJF, MAM, JJA, ONS)
    % Usage: [tnew, newdata] = completeyear(t, d, dim)
    %        [tnew, newdata] = completeyear(t, d, dim, option)
    %   where dim indicates dimension:
    %       -can leave empty [] for using the last non-singleton dimension
    %   where option indicates the starting year:
    %       -string 'season' for 12
    %       -string 'standard' for standard month 1-12 average
    %       -could also allow any number... but right now can't think of situation where
    %           that would be useful

    fixmonthid = 1; % fix so that '1' is the first month of the seasonal-year, and year ids along with it?

    %% Initial stuff, parse
    assert(isvector(t),'Bad input.');
    assert(nargin<=4 && nargin>=2,'Too many args.');
    % Get time dimension
    if exist('dim')~=1, auto = true;
    elseif isempty(dim), auto = true;
    else, assert(isscalar(dim),'Dimension must be scalar.'); auto = false;
    end
    % Retrieve time dimension, and verify
    if auto, dsz = size(d); dim = find(dsz>1,1,'last'); end
    assert(length(t)==size(d,dim),'Time vectors and data do not match.');
    % Season switch
    if exist('option')~=1, option = 'standard'; end
    switch lower(option)
    case {'season','seasonal'}, monthstart = 12;
    case {'standard',''}, monthstart = 1;
    otherwise, error('Unknown switch.');
    end

    %% Adjust time series for complete years
    tv = datevec(t(:));
    mstart = find(tv(:,2)==monthstart,1,'first');
    mend = find(tv(:,2)==mod(monthstart-2,12)+1,1,'last');
        % above, 1-->-1-->12, or 12-->10-->10-->11
    tnew = t(mstart:mend);

    %% Artifically change time series so December has "year" corresponding to the following year
    %% and all months are shifted over by 1. Can call this a "pseudoyear" or "season-year"
%    disp('before'), histc(floor(datenum2year(tnew)),min(tv(:,1)):max(tv(:,1)))'
    if fixmonthid && monthstart==12
        tv = datevec(tnew);
        filt = tv(:,2)==12;
        tv(filt,1) = tv(filt,1)+1;
        tv(:,2) = mod(tv(:,2),12)+1;
            % above, 12-->0-->1, and everything else just incremented by 1
        tnew = datenum(tv);
    end
%    disp('after'), histc(datenum(tv(:,1)),min(tv(:,1)):max(tv(:,1)))'
%    tv(end-11:end,:)

    %% And adjust data
    dnew = slice(dim,mstart:mend,d);
%    size(tnew), size(dnew)
