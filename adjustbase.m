function [ CorrectedData ] = adjustbase( x, y, t, Newbase, Data, varname )
    % Adjusts monthly, pointwise anomaly base period using a simple nearest-neighbour scheme.
    % Usage: [ CorrectedData ] = adjustbase( x, y, t, Newbase, Data, varname )
    %        [ CorrectedData ] = adjustbase( Data, varname )
    %       -'x' and 'y' are longitude/latitudes
    %       -'t' is a vector of datenums
    %       -'varname' is the name for saving Data
    %       -'Data' must be of shape x by y by time, and be composed of monthly
    %           anomalies in full, 12-month years during the period of
    %           retrieval for a new base
    %
    %   NOTE what would "exact" proximity weighting look like? well a nearest-neighbor
    %   would look like the downsampling from my downsample function, but linear-weight 
    %   based on proximity to other points would maybe be based on some kind of
    %   weighted geographic center of grid cells within the threshold distance radius...
    %   super complicated actually. for now, we just use grid-center proximity

    %% Basic check
    assert(nargin==4 || nargin==6,'Bad input; check documentation.');
    if nargin==4, varname = Newbase; Data = t; Newbase = y; t = x; end
    assert(ischar(varname),'Varname argument must be string.');
    assert(ndims(Data)==3,'Data must be x by y by time, or y by x by time.');

    %% Check base period, time
    assert(numel(Newbase)==2,'DataNB must be a length-2 vector.');
    % range valid?
    N1 = datenum([Newbase(1) 1 1 0 0 0]); 
    N2 = datenum([Newbase(2) 12 31 59 59 59]);
    assert(any(N1>=t) && any(N2<=t), ...
        'Invalid base range, or input datenum vector. New range must fall within data time.');
    % consecutive months?
    tvec = datevec(t);
    texpect = mod([tvec(1,2):tvec(1,2)+length(t)-1]'-1,12)+1;
        % consecutive progression of months from start month
    assert(all(tvec(:,2)==texpect),'Input must be MONTHLY.');
    % get ids
    Newbase1 = find(tvec(:,1)==Newbase(1),1,'first');
    Newbase2 = find(tvec(:,1)==Newbase(2),1,'last');
    NewbaseN = Newbase(2)-Newbase(1)+1;

    %% Constants
    Maxdist = 1.5e3; % 1500km ~= 3 grid cells on equator
    Display = 0; % display data?
    ReDo = 1;
    Maxdist = 0;
    Minyear = (NewbaseN/2)-1; % default; e.g. 30-year period == 14 years, 20 == 9
    Minyear = 0;
    
    %% Get datapoints; for NaN points, will weight by difference out to some threshold
    %% LABOR-INTENSIVE, so save results
    % Primitive; for now just assume we have a SINGLE base
    fname = [varname '_CorrectionTo' num2str(Newbase(1)) '-' num2str(Newbase(2)) '.mat'];
    if exist(fname)==2 && ~ReDo
        %% Just load
        load(fname,'Corrections');
        % ...that's it! just include some other params for plots
        nx = size(Corrections,1); ny = size(Corrections,2);
        DataNB = reshape(Data(:,:,Newbase1:Newbase2),[nx ny 12 NewbaseN]);
    else
        %% Check dimensions
        assert(isvector(x) && isvector(y) && isvector(t),'Dimensions must be vectors.');
        nx = length(x); ny = length(y); nt = length(t);
        assert(ndims(Data)==3 && size(Data,3)==nt && size(Data,1)==nx && size(Data,2)==ny, ...
                'Dimensions do not match.');
            % don't allow 3D compatibility... because I don't think there are gridded
            % historical 3D datasets with major NaN patches... would never need to apply it

        %% For each point during time of interest, check if we have enough Data
        % Kennedy et. al require 14 years; we do same
        DataNB = reshape(Data(:,:,Newbase1:Newbase2),[nx ny 12 NewbaseN]);
        Corrections = NaN(nx,ny,12);
        for ii=1:nx, for jj=1:ny, for mm=1:12
            if sum(isfinite(DataNB(ii,jj,mm,:)))>=Minyear
                Corrections(ii,jj,mm) = nanmean(DataNB(ii,jj,mm,:),4);
            else 
                %% Estimate necessary correction
                % get distance to gridpoints
                distances = geodist(x,y,x(ii),y(jj)); % should output an nx by ny array
                filt = distances<=Maxdist & ...
                    sum(isfinite(DataNB(:,:,mm,:)),4)>=Minyear;
                [d1, d2] = find(filt); % locations close, AND with valid data
                if isempty(d1), Corrections(ii,jj,mm) = NaN;
                    % no valid datapoints, anywhere near cell location
                else
                    % get weights for average
                    idist = zeros(length(d1),1); ibase = zeros(length(d1),1);
                    for zz=1:length(d1)
                        idist(zz) = distances(d1(zz),d2(zz));
                        ibase(zz) = nanmean(permute( ...
                            DataNB(d1(zz),d2(zz),mm,:),[4 1 2 3]),1);
                            % get climate estimate from that gridpoint
                    end
                    % and get estimate
                    iweight = Maxdist-idist;
                    iweight = iweight/sum(iweight);
                    Corrections(ii,jj,mm) = sum(ibase.*iweight);
                        % NOTE, this may still be NaN
                end
            end
        end, end, end
%        end, end, ii, end
        save(fname,'-v7.3','Corrections');
    end
%    max(max(Corrections,[],2),[],1)
%    min(min(Corrections,[],2),[],1)

    %% And apply (with extra checks in case we loaded from bad file)
    CorrectedData = Data + Corrections(:,:,tvec(:,2));
        % repmats Corrections array with corresponding months

    %% Display differences: generate plot of current base period, number count,
    %% and corrected base period with number count
    % REMEMBER in pcolor, 1st dimension is y, INCREASING with ascending index
    % ("down"); 2nd dimension is x, INCREASING with ascending index ("right")
    if Display
        % initial stuff
        fDisplay=figure;
        mycolormap('bwr',41);
        SampleMonth = 1; % try, for example, January
        Oldbase = [1961 1990]; % shouldn't be required for input
        OldbaseN = Oldbase(2)-Oldbase(1)+1;
        Oldbase1 = find(tvec(:,1)==Oldbase(1),1,'first');
        Oldbase2 = find(tvec(:,1)==Oldbase(2),1,'last');
        DataOB = reshape(Data(:,:,Oldbase1:Oldbase2),[nx ny 12 OldbaseN]);
        CorrectionMask = sum(isfinite(Data),3)==0; % catches land or sea-
            % locations; this mask is implicitly applied when we correct
            % Data using the Corrections matrix
        Corrections(repmat(CorrectionMask,[1 1 12])) = NaN;
        % mean anomaly in old base period, point by point
        subplot(3,2,1);
        pcolor(x,y,nanmean(DataOB(:,:,SampleMonth,:),4)');
        set(gca,'CLim',[-1 1]); colorbar
        % count
        subplot(3,2,2);
        pcolor(x,y,sum(isfinite(DataOB(:,:,SampleMonth,:)),4)');
        set(gca,'CLim',[-OldbaseN OldbaseN]); colorbar
        % mean anomaly in new base period, point by point
        subplot(3,2,3);
        pcolor(x,y,nanmean(DataNB(:,:,SampleMonth,:),4)');
        set(gca,'CLim',[-1 1]); colorbar
        % count
        subplot(3,2,4);
        pcolor(x,y,sum(isfinite(DataNB(:,:,SampleMonth,:)),4)');
        set(gca,'CLim',[-NewbaseN NewbaseN]); colorbar
        % "corrections"; mean anomaly in new base period with interpolation
        subplot(3,2,5);
        pcolor(x,y,Corrections(:,:,SampleMonth)');
        set(gca,'CLim',[-1 1]); colorbar
        drawnow;
        pause(10);
        close(fDisplay);
    end

