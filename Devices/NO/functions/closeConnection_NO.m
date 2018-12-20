function connection = closeConnection_NO
% closeConnection_NO 
%   Detailed explanation goes here
    AO_StopSave();
    AO_CloseConnection();
    connection = AO_IsConnected;
end

