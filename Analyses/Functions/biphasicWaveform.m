function wf = biphasicWaveform(amp, pw, ipd, sr)
% wf = biphasic_waveform(amp, pw, [ipd], [sr])
%   makes a symmetric, biphasic, cathode-leading ("Lilly") waveform
%   Inputs
%   :amp:       double      The amplitude of the waveform in [uA]
%   :pw:        double      The pulse width of the waveform in [us]
%   :ipd:       double      The interpulse duration of the waveform in [us]
%   :sr:        double      The sample rate of the waveform
%   Output
%   :wf:        vector      The waveform as a vector
%
%                 +----+
%                 |    |
%                 |    |
%                 |    |
% -------+    +---+    +-------
%        |    | \
% (amp)--|    |  (ipd)
%        |    |
%        +----+
%           \
%            (pw)

    pws = floor(pw*sr/1e6);
    ipds = floor(ipd*sr/1e6);
    
    wf = zeros(1,pws*2+ipds); 
    wf(1:pws) = -amp;
    wf(end-pws+1:end) = amp;
    wf(end+1) = 0; % ensure that last sample is zero
end