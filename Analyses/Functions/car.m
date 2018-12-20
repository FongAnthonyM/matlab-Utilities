function [ processed ] = car(target, reference, both)
% car
%   Returns the target with common average referencing based on the inputs.
%   If only "target" is given then the target's singals are used for 
%   CARing. If a "reference" is given with "target" then the "reference"
%   signals alone are used for CARing. "both" can be added to specify if
%   both "target" and "reference" are used for CARing. False for
%   "reference" only and True for both "target" and "reference".
%   Parameters
%   :target:        matrix      The signals to common reference average 
%   :reference:     matrix      The signals used for referencing
%   :both:          boolean     Determines if target and reference are both
%                               used for the common average referencing
%   Output
%   :processed:     martix      The common reference averaged signals
    
    narginchk(1,3)

    [~, n_targets] = size(target);
    if nargin == 1
        ref = target;
    else
        if nargin < 3 || ~both
            ref = reference;
        else
            ref = [target, reference];
        end
    end
    
    processed = target - repmat(nanmean(ref,2), 1, n_targets);
end

