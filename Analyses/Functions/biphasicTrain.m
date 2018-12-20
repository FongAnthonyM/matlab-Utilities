function [ y ] = biphasicTrain(amp, pw, ipd, f, dur, sr, lz)
% biphasicTrain
%   Creates a biphasic waveform train
%   Inputs
%   :amp:       double      The amplitude of the waveform in [uA]
%   :pw:        double      The pulse width of the waveform in [us]
%   :ipd:       double      The interpulse duration of the waveform in [us]
%   :f:         double      Pulse repetition rate in [Hz]
%   :dur:       double      Pulse train duration in [s]
%   :sr:        double      The sample rate of the waveform
%   :lz:        logical     An optional argument to add leading zeros to
%                           the waveform
%   Output
%   :y:         vector      The biphasic waveform pulse train
    
    if nargin < 7
        lz = false;
    end
    wf = biphasicWaveform(amp, pw, ipd, sr);
    pt = constantPulser(f, dur, sr, lz);
    y = convolve(pt, wf);
end

