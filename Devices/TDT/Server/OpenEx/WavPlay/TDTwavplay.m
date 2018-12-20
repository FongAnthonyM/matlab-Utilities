close all; clear all; clc;

TD = TDEV();
TD.standby;

new_sample_rate = TD.FS{1};

% put path of .wav file here
wav_filename = 'C:\Windows\Media\recycle.wav';

% resample it
[data, sample_rate] = audioread(wav_filename);
[p, q] = rat(sample_rate/new_sample_rate, 0.0001);
try
    new_data = resample (data, q, p);
catch
    warning(['Problem occurred during resample. Signal Processing Toolbox is required. Assuming wav file was sampled at ' num2str(new_sample_rate)])
    new_data = data;
end

Ldata = new_data(:,1);

% normalize to 1
Ldata = Ldata ./ max(Ldata);

% set my number of samples
mySamples = numel(Ldata);
TD.write('dur', mySamples);
TD.write('dCh1', Ldata);
TD.preview;

% begin playback
TD.write('trig', 1)
pause(.05)
TD.write('trig', 0)

% wait for playback to finish
while TD.read('playback') > 0
    pause(.1)
end

pause(1)
TD.standby;