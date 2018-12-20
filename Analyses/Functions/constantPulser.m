function pt = constantPulser(f, dur, sr, lz)
% constant_rate_pulser(f, dur, [sr])
%   generate a regular, constant-frequency pulse train
%   Inputs
%   :f:     double      Pulse repetition rate in [Hz]
%   :dur:   double      Pulse train duration in [s]
%   :sr:    double      Sample rate of pulse train [Hz]
%   :lz:    logical     An optional argument to add leading zeros to the
%                       pulse train
%   Output
%   :pt:    vector      The pulse train

    if nargin < 4
        lz = false;
    end
    
    ipis = floor(sr/f);
    samples = floor(dur*sr);
    
    if lz
        start = ipis;
        plen = samples + ipis;
    else
        start = 1;
        plen = samples;
    end
    
    pt = false(1, plen);
    for i=start:ipis:plen-ipis
        pt(i) = true;
    end
end