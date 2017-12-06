function [] = myprint( fh, fname, varargin)
    % Print vector and DPI graphics. Input file name; if it is not preceded by
    % directory (myprint.m detects directory by searching string for "/", then
    % we use the default directory from dict_filesys/myfilesys. if you want it saved
    % in the current directory, just use './filename'.
    %

    %% Initial/parse
    fprintf('Printing figure: %s\n',fname);
    d = dict_filesys(); % myfilesys
    printdir = d.figures; 
    % print EPS in same directory?
    if isfield(d,'pub')
        pubdir = d.pub; 
    else; 
        pubdir = printdir; 
    end
    % flags?
    noeps = false; nopng = false;
    if ~isempty(varargin)
        assert(length(varargin)==1,'Too many input arguments.');
        assert(ischar(varargin{1}),'Bad input argument. Must be character string "switch."');
        switch lower(varargin{1})
        case 'noeps'
            noeps = true;
        case 'nopng'
            nopng = true;
        case 'jpg'
            jpgflag = true; % use this as bitmap image
        otherwise; error('Bad switch: %s',varargin{1});
        end
    end
    % print where?
    if isempty(strfind(fname,'/')); 
        pngname = [printdir fname '.png'];
        epsname = [pubdir fname '.eps'];
    else
        pngname = [fname '.png']; epsname = [fname '.eps'];
    end % otherwise we input file string

    %% Paper considerations (set bounding box (figure size) to paper size, so e.g. browsing EPS with gsview is doable; otherwise is often cutoff 
    %% or hard to view. should not affect reading by LaTeX and grahpicx)
    fpos = myget(fh,'Position'); s = myget(fh,'Draw'); lw=s.Line.LineWidth;
    set(fh, ... % 'PaperType','custom', % setting PaperSize automatically sets "PaperType" to "custom"
        'PaperUnits','inches','PaperSize',fpos(3:4), ...
        'PaperPositionMode','manual','PaperPosition',[0 0 (fpos(3:4)+2*lw/72)]); % auto means size matches displayed size

    %% Print
%    dpi = '300';% get(fh,'Position')
    dpi = myget(fh,'DPI');
    print(fh,'-dpng',['-r' num2str(round(dpi))],pngname);% get(fh,'Position')
    if ~noeps;
        print(fh,'-depsc',epsname);% get(fh,'Position')
    end

