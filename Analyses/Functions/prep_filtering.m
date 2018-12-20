function [ new_data ] = prep_filtering(data, but, notches, ds_fs, fs)
% prep_filtering
%   A function that filters and down samples the data
%   Parameters
%   :data:      matrix          The singal data
%   :but:       digitalFilter   A filter to run before downsampling default butterworth 
%   :notches:   cell array      Array of notch filters to fun after downsampling
%   :fs:        double          Original sample rate
%   :ds_fs:     double          New sample rate
%   Output
%   :ds_data:   matrix          New preprocessed data
    % Make default filters if there are no new ones
    if ~isa(but, 'digitalFilter')
        but = designfilt('bandpassiir', 'FilterOrder',4,'HalfPowerFrequency1',0.5,'HalfPowerFrequency2',256,'DesignMethod','butter','SampleRate',fs);
    end
    if ~isa(notches,'cell') || isa(notches,'digitalFilter')
        notches = cell(3,1);
        notches{1} = designfilt('bandstopiir', 'FilterOrder',2,'HalfPowerFrequency1',58,'HalfPowerFrequency2',62,'SampleRate', ds_fs);
        notches{2} = designfilt('bandstopiir', 'FilterOrder',2,'HalfPowerFrequency1',118,'HalfPowerFrequency2',122,'SampleRate', ds_fs);
        notches{3} = designfilt('bandstopiir', 'FilterOrder',2,'HalfPowerFrequency1',178,'HalfPowerFrequency2',182,'SampleRate', ds_fs);
        notches{4} = designfilt('bandstopiir', 'FilterOrder',2,'HalfPowerFrequency1',238,'HalfPowerFrequency2',242,'SampleRate', ds_fs);
    end
    
    [p, q] = rat(ds_fs/fs,0.00000001);
    
    if iscell(data)
        new_data = [];
        for index = 1:length(data)
            % Run first filter
            %filt_data = data{index}';

            % Downsample data using resample
            ds_data = resample(filt_data, p, q);

            % Apply castcaded notch filters
            for j = 1:length(notches)
                ds_data = filtfilt(notches{j}, ds_data);
            end
            new_data(index,:) = ds_data';
        end
    else
        % Run first filter
        %data = filtfilt(but,data');

        % Downsample data using resample
        ds_data = resample(data, p, q);

        % Apply castcaded notch filters
        for index = 1:length(notches)
            ds_data = filtfilt(notches{index},ds_data);
        end
        new_data = ds_data';
    end
end

