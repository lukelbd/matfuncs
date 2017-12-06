function [ data ] = NaNfill( input1, data, fillval )
    % Fills array "data" at IDs "filt" OR satisfying the anonymous function
    % test(data) with some fill-value. Default is NaN.
    % Usage: data = NaNfill( filt, data )
    %        data = NaNfill( filt, data, fillval )
    %        data = NaNfill( test, data, ...)
    assert(any(nargin==[2 3]),'Bad number of input args.');
    if exist('fillval')~=1, fillval = NaN; end
    if isa(input1,'function_handle');
        data(input1(data)) = fillval;
    else
        data(input1) = fillval;
    end
        % ...simple as that

