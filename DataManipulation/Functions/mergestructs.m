function y = mergestructs(a, b, replace)
% mergestructs
% Merges two structures into one new structure.
% Inputs
%   :a:         struct      Original structure. 
%   :b:         struct      Structure to add to the original.
%   :replace:   logical     Deterimes whether to override common fields.
% Outputs
%   :y:         struct      The combined structure of A and B.
    
    % Error Check
    if ~isstruct(a) || ~isstruct(b)
        error('Both A and B must be structures.')
    end
    
    % Determine which Structure has Priority
    if nargin < 3 || replace
        y = a;
        x = b;
        fields = fieldnames(b);
    else
        y = b;
        x = a;
        fields = fieldnames(a);
    end
    
    % Add the Other Structure Fields
    for i = 1:length(fields)
        field = fields{i};
        y.(field) = x.(field);
    end
end

