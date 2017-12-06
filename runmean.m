function ynew = runmean( y, period, varargin );
%function [ ynew, runids ] = runmean( y, period, varargin );
    % Usage: yrun = runmean( y, period );
    % gets running mean along dimension 1 at smoothing interval period

    % Check
    assert(nargin==2 || nargin==3,'Wrong number of input args.');
%    assert(mod(period,2)==1, 'Running period must be odd-number.');
    % If data is vector, flatten it
    if isvector(y); y = y(:); end
    sizey = size(y);
    dim1 = find(sizey~=1,1,'first');
    yperm = [dim1:ndims(y) 1:dim1-1]; % permute to put 1st non-singleton along dim 1
    y = permute(y,yperm);
    nextra = prod(sizey(dim1+1:end));
    sizey = size(y); % must re-declare this
    n1 = sizey(1); 
%    pm = (period-1)/2; n1new = n1-pm*2; 
    n1new = n1-period+1;
    if isempty(varargin);
%        minfilt = (pm+1)/2; % e.g. for 5 year smooth, require at least 3 years of data
        minfilt = floor(period/2); % e.g. for 5/6 year smooth, require at least 3 years of data
    else
        minfilt = varargin{1}; % user should place "1", "0", or "NaN" to not filter
        assert(numel(minfilt)==1 && all(round(minfilt(:))==minfilt(:)),'Bad input.');
    end
    % Other checks
    assert(n1>=period, 'Running period is too long.');
    % Go
    y = reshape(y,[n1 nextra]); ynew = NaN(n1new, nextra);
%    for jj=1:nextra; for ii=pm+1:n1-pm;
    for jj=1:nextra; for ii=period:n1;
        if sum(isfinite(y(ii-period+1:ii,jj)))<minfilt
            ynew(ii-period+1,jj) = NaN;
        else
            ynew(ii-period+1,jj) = nanmean(y(ii-period+1:ii,jj));
        end
    end; end
    ynew = reshape(ynew,[n1new sizey(2:end)]);
    ynew = ipermute(ynew,yperm);
