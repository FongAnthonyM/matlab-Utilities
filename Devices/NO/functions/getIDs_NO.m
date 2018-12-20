function IDs = getIDs_NO(names, buffer)
% getIDs_NO
%   From the channel names get IDs and set buffers
    if connect2NeuroOmega
        error('Could not Connect to Neuro Omega')
    end
    total = length(names);
    IDs = cell(1,total);
    for index = 1:total;
        % Get ID of the channel and set its buffer
        IDs{index} = AO_TranslateNameToID(char(names(index)), length(char(names(index))));
        if AO_AddBufferingChannel(IDs{index}, buffer); 
            error('Channel %s could not be added to buffering\n', char(names(index)))
        end
    end
end

