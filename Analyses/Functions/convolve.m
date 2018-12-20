function y = convolve(pt, wf)
% convolve(pt, wf)
%   convolve a pulse train with a waveform or waveforms
%   Input
%   :pt:    vector      Pulse train (logical array)
%   :wf:    vector      Waveform or cell array of waveforms if cell array: 
%                       length(wf) === sum(pt) 
%   Output
%   :y:     vector      A train of waveforms

    y = zeros(size(pt));
    ipt = find(pt);
    dp = diff(ipt);
    bad = false(size(ipt));
    
    cwf = iscell(wf);
    
    if cwf
        if length(wf) ~= sum(pt)
            error('if wf is a cell array, length(wf) === sum(pt)');
        end
        n = cellfun(@length, wf);
        bad(2:end) = dp < n(1:end-1);
    else
        n = length(wf);
        bad(2:end) = dp < n; 
    end
    
    if sum(bad) > 0
        fprintf('removed %d pulses that overlapped\n', sum(bad));
    end
    ipt(bad) = []; % dont allow overlapping pulses

    for i=1:length(ipt)
        if cwf
            y(ipt(i):ipt(i)+n(i)-1) = wf{i};
        else
            y(ipt(i):ipt(i)+n-1) = wf;
        end
    end

end