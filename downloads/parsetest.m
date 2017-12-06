
tstparse = 0;
p = inputParser; 
p.KeepUnmatched = true;
addRequired(p,'code',@ischar)
addRequired(p,'args',@iscell)
addOptional(p,'trigger','afddas',@ischar)
parse(p,'myfigure',{1,2,3},'asdf','unmatched',1)

