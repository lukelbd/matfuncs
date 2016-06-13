function [ clims, deftrig ] = myclims(data, varname, idunit);
    % Assigns color limits for various variable data, for plotting.
    % Must take note of the "working units" for each parameters.

    deftrig = true;
    switch varname
    case 'z'
        if idunit==500
            clims = [450 600]; deftrig = false;
        end
    case 'qgpv'
        if idunit==250
            clims = [-2e-5 2e-5]; deftrig = false;
        end
    case 'absvo'
        if idunit==250
            clims = [-2e-5 2e-5]; deftrig = false;
        end
    end
    if deftrig
        clims = [prctile(data(:),5) prctile(data(:),95)];
    end
   
end
