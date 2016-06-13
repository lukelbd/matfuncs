function [] = myprint( fh, fname )
    % Print vector and DPI graphics. Input file name; if it is not preceded by
    % directory (myprint.m detects directory by searching string for "/", then
    % we use the default directory from dict_filesys/myfilesys. if you want it saved
    % in the current directory, just use './filename'.
    %

    %% Initial
    fprintf('Printing figure: %s\n',fname);
    d = dict_filesys(); % myfilesys
    printdir = d.figures; 
    % print EPS in same directory?
    if isfield(d,'pub')
        pubdir = d.pub; 
    else; 
        pubdir = printdir; 
    end
    % where?
    if isempty(strfind(fname,'/')); 
        pngname = [printdir fname '.png'];
        epsname = [pubdir fname '.eps'];
    else
        pngname = [fname '.png']; epsname = [fname '.eps'];
    end % otherwise we input file string

    %% Print
    dpi = '300';% get(fh,'Position')
    print(fh,'-dpng',['-r' dpi],pngname);% get(fh,'Position')
    print(fh,'-depsc',epsname);% get(fh,'Position')

end
