function result = connect2NeuroOmega
% connect2NeuroOmega
%   Connect to the Neuro Omega
    DspMac  = 'bc:6a:29:cc:be:6F'; %read from NeuroOmega box
    PcMac   = '10:C3:7B:E7:F6:80'; %get from windows comamand line, getmac
    AdapterIndex = -1;
    value = AO_StartConnection(DspMac,PcMac,AdapterIndex);
    result = 1;
    for j=1:100
        pause(1);
        if AO_IsConnected 
           fprintf('Connected...\n')
           result = 0;
           break;
        end
    end
end

