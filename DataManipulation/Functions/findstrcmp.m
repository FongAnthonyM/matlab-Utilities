function [L, I] = findstrcmp(a, t)
% findstrcmp
% Finds all matching string in a cell array and returns it as a logical and its indices
% Input
% :a:   cell array  The cell array to search through for the matching strings
% :t:   cell array  The cell array of string to find in "a"
% Outputs
% :L:   logical     The logical of the matching strings in "a"
% :I:   vector      The vector of indicies of matching strings in "a" 
    if ischar(t)
        t = {t};
    end
    L = false;
    for s = 1:length(t)
        L = L | strcmp(a, t{s});
    end
    I = find(L);
end

