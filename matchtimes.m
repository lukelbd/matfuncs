function [tnew, d1new, d2new] = matchtimes(t1, t2, d1, d2, dim)
    % Matches disparate datasets to span the same time interval. time is assumed
    % to be on the last non-singleton dimension
    % Usage: [t, d1, d2] = matchtimes(t1, t2, d1, d2)
    %        [t, d1, d2] = matchtimes(t1, t2, d1, d2, dim)
    %   where t1, d1 are time vectors and dataset; t2, d2 is the other pair
    %   dim is optional, dimension of "time" in datasets:
    %       use scalar for same dimension on d1, d2, or length-2 vector
    
    dayinterval = 1/24; % we round times to nearest hour
    %% Initial stuff
    assert(nargin==4 || nargin==5,'Bad input.');
    if exist('dim')==1
        assert(isscalar(dim) || numel(dim)==2,'Bad dimension input.');
        if isscalar(dim), dim = [dim dim]; end
        t1id = dim(1); t2id = dim(2);
    else
        d1sz = size(d1); d2sz = size(d2); 
        t1id = find(d1sz>1,1,'last'); t2id = find(d2sz,1,'last');
    end
    assert(isvector(t1) && isvector(t2),'Time must be in vector form of datenums.');
    assert(length(t1)==size(d1,t1id) && length(t2)==size(d2,t2id),'Time vectors and data do not match.');
    %% Round similar times to nearest <interval>
    t1 = roundto(dayinterval,t1);
    t2 = roundto(dayinterval,t2);
    %% Run
    tnew = unique(sort([t1(:); t2(:)]));
    tends = [range(t1); range(t2)];
    tnew(tnew<max(tends(:,1)) | tnew>min(tends(:,2))) = [];
%    range(diff(tnew))
%    unique(diff(tnew))
%    assert(all(diff(tnew)>=30/(3600*24)),'Seems to be rounding errors in time vectors. Fix manually by converting to datevec and rounding to nearest appropriate time unit (hour, day).');
%        % if any observations differ by less than 30 seconds, flag it
    %% Filter data
    min1 = find(t1==tnew(1)); min2 = find(t2==tnew(1));
    max1 = find(t1==tnew(end)); max2 = find(t2==tnew(end));
%    max1-min1, max2-min2
    d1new = slice(t1id,min1:max1,d1);
    d2new = slice(t2id,min2:max2,d2);
%    size(tnew), size(d1new), size(d2new)
