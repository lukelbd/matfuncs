function [ tnew ] = datenum2year( t )
    % Converts matlab datenum to year-format for monthly or daily time series where
    % the x-axis displays years. Requires function 'eomday'. Apparently this func exists
    % as 'yearfrac' in Financial Toolbox, but not everyone has it and this is really simple.
    % Usage: tnew = datenum2year(t)
    %   t must be a vector of datenumbers, daily or monthly data only
    %       -if you have hourly data, why would you want to express as year fractions?
    %       -if you have yearly data, making a border vector for pcolor plotting is easy;
    %           just [y, y(end)+1]
    %   appropriate for x/y axis of line plots or color plots

    %% Assess input
    assert(nargin==1 && isvector(t),'Bad input.');
    t = datevec(t(:));
    %% Two options
    if all(t(:,3)==t(1,3)) % all days identical?
        % this is a monthly dataset; we CENTER it, looks best for plotting grid, but 
        tnew = t(:,1) + (1/24)*((t(:,2)-1)*2+1); % so 1--> 1/24, 2-->3/24, 3-->5/24
    elseif all(t(:,4)==t(1,4)) % all hours identical?
        % this is a daily dataset
        tnew = t(:,1) + (1/12)*(t(:,2)-1) + (1/12)*(1./eomday(t(:,1),t(:,2))).*(t(:,3)-1+0.5);
            % centered on hour 12 of day
    else
        % this is an hourly dataset
        tnew = t(:,1) + (1/12)*(t(:,2)-1) + (1/12)*(1./eomday(t(:,1),t(:,2))).*(t(:,3)-1+t(:,4)/24);
            % centered on hour of observation
    end
