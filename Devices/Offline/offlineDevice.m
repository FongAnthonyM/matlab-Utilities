classdef offlineDevice < Device
% offlineDevice
%   An object that acts as a device but uses local data.
%   :self:          handle					A handle that points to this offlineDevice object
%   :name:          string                  The name of this device
%   :parent:		handle					The handle of the parent of this object
%
%
%   :max_fs:                double          The highest sampling rate that the TDT will use
%   :sample_rate:           double          The sample rate that data will be collected at

properties
    start_tic
    pre_sample
end

methods
    %% ---- Methods ---- %%
    function self = offlineDevice(name, f_path, sample_rate, max_fs, parent)
    % offlineDevice
    %   Intitializes a offlineDevice object. Name and parent are optional arguments.
    %   Input
    %   :name:          string      The name of the server connecting to
    %   :parent:        handle      The oject that will be the parent of the connection
    %   Output
    %   :self:          handle      This TDT device object
        % Assign Server Name %
        if nargin > 0
            self.name = name;
        else
            self.name = 'Offline';
        end
        
        % Assign File %
        if nargin > 1
            if isempty(f_path)
                self.f_path = '';
            else
                self.f_path = f_path;
                self.file = load(f_path, 'raw_data');
                self.raw_data = self.file.raw_data;
            end
        else
            self.f_path = '';
            self.file = [];
            self.raw_data = [];
        end
        
        % Assign Sample Rate %
        if nargin > 2
            self.sample_rate = sample_rate;
        else
            self.sample_rate = NaN;
        end
        
        % Assign Max Sample Rate %
        if nargin > 3
            self.max_fs = max_fs;
        else
            self.max_fs = NaN;
        end
        
        % Assign Server to Parent Object %
        if nargin > 4
            self.parent = parent;
        else
            self.parent = [];
        end
    end
    
    function channels = channelStruct(self)
        channels.names = {'First','Second','Third','Fourth'};
        channels.IDs = {};
        channels.chans = [1 2 3 4];
        channels.type_names = {'t_Hipp','r_Hipp','t_Amyg','r_Amyg','Reference','Stim'};
        channels.record_i = [1 2];
        channels.t_values = [7 7 7 7];
    end
    
    function channels = selectChannels(self, varargin)
        channels = OFF_selectChannels(varargin);
    end
    
    function initDataCollection(self)
    % initDataCollection
    %   Intitializes data collection from raw data.
    %   Input
    %   :self:          handle      The offlineDevice object
        self.start_tic = tic;
        self.pre_sample = 1;
    end
    
    function [raw_channels, new_ts] = getData(self, IDs, timestamps)
    % getData
    %   Get the data from the raw data since the initialization or the last getData call
    %   Inputs
    %   :self:          handle              The offlineDevice object
    %   :IDs:           cell array          Array of the channnel IDs to get data from 
    %   Outputs
    %   :raw_channels:          cell array          The data from all of the channels in a cell array
    %   :sample_rate:           double              The sample rate of data
    %   :samples_perchannel:    double              The number of samples recorded from each channel
    %   :last_sample:           double              The absolute sample number of the last sample in the new data
        
        now = toc(self.start_tic);
        end_sample  = floor(now*self.sample_rate);
        for index = 1:length(IDs)
            raw_channels{index} = self.raw_data(IDs{index}, self.pre_sample:end_sample);
        end
        
        self.pre_sample = end_sample + 1;
        
        % Calcuate Output Information %
        samples_perchannel = length(raw_channels{1});
        sample_rate = self.sample_rate;
        
        [new_ts, ~] = makeTimestamp(self, timestamps, 'record_data', samples_perchannel, end_sample, 0, sample_rate);
    end
    
    function buffer = createBiphasicBuffer(self, tc, amp, pw, ipd, f, dur, sr)
    % createBiphasicBuffer
    %   Create biphasic square wave signals to be used for stimulation
    %   Inputs
    %   :self:          handle      The TDT device object
    %   :tc:            double      The number of biphasic square wave signals to create
    %   :amp:           double      The ampludide of the singal in [uA]
    %   :pw:            double      The pulse width in [ms]
    %   :ipd:           double      The interpulse delay in [ms]
    %   :f:             double      The pusle frequency in [Hz]
    %   :dur:           double      The duration of the signal in [s]
    %   :sr:            double      An optional argument for the sample rate
    %   Outputs
    %   :buffer:        matrix      The the biphasic square wave signals where each row is a signal
        % If the sample rate has not be set then use the max sample rate %
        if nargin < 8
            sr = self.max_fs;
        end
        
        % Create Singals %
        y = biphasicTrain(amp, pw, ipd, f, dur, sr, true);
        buffer = repmat(y, [tc, 1]);
    end
    
    function [returns] = initStimBuffer(self, buffer)
    % initTDTstimBuffer
    %   Initializes the stimulation buffer for the TDT
    %   Input
    %   :self:          handle      The TDT device object
    %   :buffer:        matrix      The row wise singals the stimulator will output
    %   Output
    %   :returns:       vector      The what is in the stimulator buffer after
    %                               loading the new signal in 
        returns = buffer;
    end
    
    function returns = stimulationParameters(self, tc, amp, pw, ipd, f, dur)
    % stimulationParameters
    %   Create biphasic square wave signals and assign them as the stimulation signal
    %   Inputs
    %   :self:          handle      The TDT device object
    %   :tc:            double      The number of biphasic square wave signals to create
    %   :amp:           double      The ampludide of the singal in [uA]
    %   :pw:            double      The pulse width in [ms]
    %   :ipd:           double      The interpulse delay in [ms]
    %   :f:             double      The pusle frequency in [Hz]
    %   :dur:           double      The duration of the signal in [s]
    %   Outputs
    %   :returns:       vector      The what is in the stimulator buffer after
    %                               loading the new signal in
        buffer = createBiphasicBuffer(self, tc, amp, pw, ipd, f, dur);
        returns = initStimBuffer(self, buffer);
    end
    
    function startStimulation(self)
    % startStimulation
    %   Starts stimulation on the offline device
    %   Input
    %   :self:          handle      The offline device object
        return
    end
    
    function stopStimulation(self)
    % startStimulation
    %   Stops stimulation on the offline device
    %   Input
    %   :self:          handle      The offline device object
        return
    end
    
    function [new_timestamp, current_index] = makeTimestamp(self, timestamps, type, samples_perchannel, e_sn, start_offset, sample_rate)
    % makeTimestamp
    %   Creates a timestamp based on sample number and type.
    %   Types of timestamp: 'record_data' 'time_aligned' 'unaligned'
    %   record_data: creates a timestamp for record data     
    %   time_aligned: creates a timestamp based on the relative zeroing of the timestamps object
    %   unaligned: creates a timestamp based only on input beginning sample number
    %   Inputs
    %   :self:                  handle              The offline device object
    %   :timestamps:            timestamp object    The timestamps object the new timestamp will be for
    %   :type:                  string              The type of timestamp being made
    %   :samples_perchannel:    double              The number of samples after the beginning sample number
    %   :beginning_sn:          double              The sample number that the timestamp will mark
    %   :start_offset:          double              The number of samples the start of the window is from the end
    %   :sample_rate:           double              The number of samples persecond
    %   Outputs
    %   :new_timestamp:         structure           The new timestamp
    %   :current_index:         double              The index of the new timestamp
        % Get Timestamp Number
        current_index = timestamps.stamp_index + 1;
        current_stamp = timestamps.stamp_number + 1;

        b_sn = e_sn - samples_perchannel + 1;
        dropped_samples = NaN;
        if strcmp(type,'record_data')
            if current_stamp-1 == 0
                b_sample_number = 1;
                e_sample_number = b_sample_number + samples_perchannel - 1;
                timestamps.zero = b_sn;
                previous_sample = 0;
            else
                b_sample_number = b_sn - timestamps.zero + 1;
                e_sample_number = b_sample_number + samples_perchannel - 1;
                previous_sample = timestamps.stamps.list(current_index-1).e_sample_number;
            end
            dropped_samples = b_sample_number - previous_sample - 1;
        elseif strcmp(type,'time_aligned')
            b_sn = e_sn - start_offset + 1;
            b_sample_number = b_sn - timestamps.zero;
            e_sample_number = e_sn - timestamps.zero;
        else
            b_sample_number = e_sn;
            e_sample_number = e_sn;
        end

        b_adj_sn = b_sample_number - timestamps.adjustment;
        e_adj_sn = e_sample_number - timestamps.adjustment;
        b_seconds = (b_sample_number-1)/sample_rate;
        e_seconds = e_sample_number/sample_rate;

        % Create Timesamp Structure
        new_timestamp.b_off_sn = b_sn;
        new_timestamp.e_off_sn = e_sn;
        new_timestamp.b_adj_sn = b_adj_sn;
        new_timestamp.e_adj_sn = e_adj_sn;
        new_timestamp.number = current_stamp;
        new_timestamp.b_seconds = b_seconds;
        new_timestamp.e_seconds = e_seconds;
        new_timestamp.b_sample_number = b_sample_number;
        new_timestamp.e_sample_number = e_sample_number;
        new_timestamp.dropped_samples = dropped_samples; 
    end
    
    function [ts, current_index] = alignedTimestamp(self, timestamps, a_ts, sample_rate, offset)
    % makeTimestamp
    %   Creates a timestamp based on sample number and type.
    %   Types of timestamp: 'record_data' 'time_aligned' 'unaligned'
    %   record_data: creates a timestamp for record data     
    %   time_aligned: creates a timestamp based on the relative zeroing of the timestamps object
    %   unaligned: creates a timestamp based only on input beginning sample number
    %   Inputs
    %   :self:                  handle              The TDT device object
    %   :timestamps:            timestamp object    The timestamps object the new timestamp will be for
    %   :a_ts:                  timestamp           The timestamp to align this timestamp to
    %   :start_offset:          double              The number of samples the start of the window is from the end
    %   :sample_rate:           double              The number of samples persecond
    %   Outputs
    %   :new_timestamp:         structure           The new timestamp
    %   :current_index:         double              The index of the new timestamp
        % Get Timestamp Number
        current_index = timestamps.stamp_index + 1;
        current_stamp = timestamps.stamp_number + 1;
        
        b_sample_number = a_ts.e_sample_number - offset;
        
        % Create Timesamp Structure
        ts.number = current_stamp;
        ts.b_adj_sn = b_sample_number - timestamps.adjustment;
        ts.e_adj_sn = a_ts.e_adj_sn;
        ts.b_seconds =(b_sample_number-1)/sample_rate;
        ts.e_seconds = a_ts.e_seconds;
        ts.b_sample_number = b_sample_number;
        ts.e_sample_number = a_ts.e_sample_number;
    end
end
    
end