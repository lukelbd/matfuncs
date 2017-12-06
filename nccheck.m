function [data, loaded] = nccheck(dirnm, basenm, vname, qtimes)
    %% Check if time instance of given variable is recorded in file, based on "varname_history" 
    % variable. This is how I plan to save data for time being.
    %
    % Usage: [data, loaded] = nccheck(dirname, basename, variable, querytimes)
    %
    % Check if data is available for the requested Matlab DATENUM-type querytimes at synoptic
    % time intervals (0UTC, 6UTC, 12UTC, and 18UTC).
    %
    loaded = false; data = [];

    filenm = [dirnm basenm]; if ~strcmp(dirnm(end),'/') && ~strcmp(dirnm(end),'\'); error('write_ncfile:Input: Directory name should have trailing "/".'); end
    histname = [vname '_history'];

     if exist(filenm)==2
        ncinf = ncinfo(filenm); 
        ncvars = {ncinf.Variables.Name};
        if any(ismember(ncvars, histname))
            data = [];
            for i=1:length(qtimes)
                itime = qtimes(i);
                ftimes = ncread(filenm, 'time'); 
                loc = find(ftimes==itime);
                if isempty(loc); error('Abnormal time: %s', datestr(itime, 'yyyy-mm-dd HH:MM')); end

                %% Starting loading data for query times. if we run into trouble, flag it.
                loaded = true;
                if ncread(filenm, histname, loc, 1)==1 % if there is recorded entry in file
                    if i==1;
                        data = ncread(filenm, vname, [1 1 loc], [Inf Inf 1]);
                        data(:,:,length(qtimes)) = NaN;
                    else
                        data(:,:,i) = ncread(filenm, vname, [1 1 loc], [Inf Inf 1]);
                    end
                else
                    data = [];
                    warning('Data not available for whole query-time range.');
                    loaded = false;
                    return;
                end
            end
        else
            warning('File exists, but queried variable not present.');
        end
    else
        warning('File does not exist.');
    end
end
