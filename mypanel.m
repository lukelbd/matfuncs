function [a] = mypanel( hpars, edge )
    % Usage: a = mypanel(hpars, edge )
    % 
    % Creates panel anchored to parent objects hpars along specified edge.
    
    switch lower(edge(1))
    case 'w'
    case 'e'
    case 's'
    case 'n'
    end
    myobjectfix(a);
