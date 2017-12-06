function yslope = runslope(x, y, period, varargin );
%function [ yslope, runids ] = runslope(x, y, period );
    % Usage: yrun = runslope( y, period );
    % gets slope along dimension 1 by LLS within periodic x-intervals 
    % Does not require x-input, because this function will generally be
    % used with evenly-spaced TIME data, it is assumed

    % Check
    assert(nargin==3 || nargin==4,'Wrong number of input args.');
%    assert(mod(period,2)==1, 'Running period must be odd-number.');
    % If data is vector, flatten it
    if isvector(y); y = y(:); end
    x = x(:);
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
    assert(isvector(x) && length(x)==size(y,1), 'Bad x-vector.');
    % Go
    y = reshape(y,[n1 nextra]); yslope = NaN(n1new, nextra);
%    for jj=1:nextra; for ii=pm+1:n1-pm;
    for jj=1:nextra; for ii=period:n1;
        %yslope(ii-pm,jj) = x(ii-pm:ii+pm)\y(ii-pm:ii+pm,jj);
        %yslope(ii-pm,jj) = y(ii-pm:ii+pm,jj)\x(ii-pm:ii+pm);
        %yslope(ii-pm,jj) = regress(y(ii-pm:ii+pm,jj),x(ii-pm:ii+pm));
%        xpick = x(ii-pm:ii+pm); ypick = y(ii-pm:ii+pm,jj);
        xpick = x(ii-period+1:ii); ypick = y(ii-period+1:ii,jj);
        if sum(isfinite(ypick))<minfilt
            yslope(ii-period+1,jj) = NaN;
        else
            coeffs = polyfit(xpick(isfinite(ypick)),ypick(isfinite(ypick)),1);
            yslope(ii-period+1,jj) = coeffs(1); 
        end
    end; end
    yslope = reshape(yslope,[n1new sizey(2:end)]);
    yslope = ipermute(yslope,yperm);
