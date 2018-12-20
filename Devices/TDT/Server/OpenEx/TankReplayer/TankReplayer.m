close all; clear all; clc;

SOURCETANK = 'DEMOTANK2';
SOURCEBLOCK = 'Block-1';
SOURCESTREAM = 'xWav';

% read the streaming data from the tank
data = TDT2mat(SOURCETANK, SOURCEBLOCK, 'TYPE', [4], 'STORE', SOURCESTREAM, 'T2', 60);
numsamples = length(data.streams.(SOURCESTREAM).data(1,:))
numchannels = size(data.streams.(SOURCESTREAM).data,1)

% connect to Workbench server
TD = actxcontrol('TDevAcc.X');
TD.ConnectServer('Local')
 
% standby mode
TD.SetSysMode(1); 
while TD.GetSysMode ~= 1
    pause(0.1)
end

% get buffer size
bufsize = TD.GetTargetSize('RZ.dCh1');
midbuf = bufsize / 2;

% load up one entire buffer
for i = 1:numchannels
    tag = ['RZ.dCh' num2str(i)];
    TD.WriteTargetV(tag, 0, data.streams.(SOURCESTREAM).data(i, 1:bufsize));
end
index = bufsize+1;

% preview mode
TD.SetSysMode(2); 
while TD.GetSysMode ~= 2
    pause(0.1)
end

% while in preview mode, write source data into buffers
while TD.GetSysMode > 1
    
    % wait until first half has played out
    while TD.GetTargetVal('RZ.sCh') < midbuf
        pause(.1)
    end

    % reached midway point, overwrite buf A and check if we are at the end
    bLooped = 0;
    for i = 1:numchannels
        tag = ['RZ.dCh' num2str(i)];
        if index+midbuf < numsamples 
            TD.WriteTargetV(tag, 0, data.streams.(SOURCESTREAM).data(i, index:index+midbuf));
        else
            % we are at the end, only write what is left
            diff = index+midbuf-numsamples;
            TD.WriteTargetV(tag, 0, data.streams.(SOURCESTREAM).data(i, index:numsamples));
            disp(['writing ' num2str(index) ' to ' num2str(numsamples)])
            TD.WriteTargetV(tag, midbuf-diff, data.streams.(SOURCESTREAM).data(i, 1:diff)); 
            disp(['writing starting at' num2str(midbuf-diff) ' to ' num2str(midbuf)])
            bLooped = 1;
        end
    end

    if bLooped
        % might want to quit here with TDT.SetSysMode(1)
        disp('looped A')
        index = diff
    else
        index = index + midbuf
    end

    % wait until the second half has played out
    while TD.GetTargetVal('RZ.sCh') > midbuf
        pause(.1)
    end

    % reached beginning, overwrite buf B and check if we are at the end
    bLooped = 0;
    for i = 1:numchannels
        tag = ['RZ.dCh' num2str(i)];
        if index+midbuf < numsamples 
            TD.WriteTargetV(tag, midbuf, data.streams.(SOURCESTREAM).data(i, index:index+midbuf));
        else
            diff = index+midbuf-numsamples;
            TD.WriteTargetV(tag, midbuf, data.streams.(SOURCESTREAM).data(i, index:numsamples));
            disp(['writing ' num2str(index) ' to ' num2str(numsamples)])
            TD.WriteTargetV(tag, bufsize-diff, data.streams.(SOURCESTREAM).data(i, 1:diff));
            disp(['writing starting at' num2str(bufsize-diff) ' to ' num2str(bufsize)])
            bLooped = 1;
        end
    end
    
    if bLooped
        % might want to quit here with TDT.SetSysMode(1)
        disp('looped B')
        index = diff
    else
        index = index + midbuf
    end
end
