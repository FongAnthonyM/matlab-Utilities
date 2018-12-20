function [ new_data ] = downNotchFilter(data, notches, ds_fs, fs)
% downNotchFilter
%   A function that filters and down samples the data
%   Parameters
%   :data:      matrix          The singal data
%   :but:       digitalFilter   A filter to run before downsampling default butterworth 
%   :notches:   cell array      Array of notch filters to fun after downsampling
%   :fs:        double          Original sample rate
%   :ds_fs:     double          New sample rate
%   Output
%   :ds_data:   matrix          New preprocessed data
    [p, q] = rat(ds_fs/fs,0.00000001);

    % Make default filters if there are no new ones
    if ~isa(notches,'cell') || isa(notches,'digitalFilter')
        notches = harmonicNotch(60, 4, 6, ds_fs);
    end
    
    if iscell(data)
        new_data = [];
        for index = 1:length(data)
            % Downsample data using resample
            ds_data = resample(data{index}', p, q);

            % Apply castcaded notch filters
            for j = 1:length(notches)
                ds_data = filtfilt(notches{j}, ds_data);
            end
            new_data(index,:) = ds_data';
        end
    else
        % Downsample data using resample
        ds_data = resample(data', p, q);

        % Apply castcaded notch filters
        for index = 1:length(notches)
            ds_data = filtfilt(notches{index},ds_data);
        end
        new_data = ds_data';
    end
end

