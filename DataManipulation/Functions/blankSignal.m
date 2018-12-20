function [s] = blankSignal(fs, t, extra)
% blankSignal
% Creates a NaN row sample vector based on sample rate, duration, and
% extended time.
% Inputs
% :fs:      double      The sample frequency of the channel
% :t:       double      The duration of singal in seconds
% :extra:   double      The extra time to add to the signal in seconds
% Outputs
% :s:       double      A NaN row sample vector of duration + extra
    if nargin < 2 
        extra = 0;
    end
    s = NaN(1, floor((t+extra)*fs));
end

