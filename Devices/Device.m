classdef Device < matlab.mixin.SetGet
% Device 
    
properties
    self
    parent
    name
    
    f_path
    file
    
    raw_data
    sample_rate
    max_fs
    
    stim_parameter_array
    stim_sequence
    stim_sequence_index = 1
    stim_parameter_index = 1
end

methods
    function self = Device(name, f_path, sample_rate, max_fs, parent)
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
        error('selectChannels was not defined in the subclass!');
    end
    
    function selectChannels(self, varargin)
        error('selectChannels was not defined in the subclass!');
    end
    
    function initDataCollection(self)
        error('initDataCollection was not defined in the subclass!');
    end
    
    function shutdown(self)
        disp('Default Device shutdown used');
    end
    
    function [raw_data, new_ts] = getData(self, IDs, timestamps)
        error('getData was not defined in the subclass!');
    end
    
    function addStimParameters(self, parameters)
    % addStimParameters
        self.stim_parameter_array(end+1,:) = parameters;
    end
    
    function setStimSequence(self, vector)
    % setStimParameters
    %   Sets the stimSquence to the provided vector.
    %   Inputs
    %   :self:          handle      The device object
    %   :vector:        vector      A vector of the stim parameter indices
    %                               to run through when stimulating
        self.stim_sequence = vector;
    end
    
    function [pi, si] = stimNextIndex(self)
    % stimNextIndex
    %   Set the Index of the stim sequence and stim parameter to the next
    %   value.
    %   Inputs
    %   :self:  handle      The device object
    %   Outpus
    %   :pi:    double      The new parameter index
    %   :si:    double      The new sequence index
        if self.stim_sequence_index >= length(self.stim_sequence)
            si = 1;
        else
            si = self.stim_sequence_index + 1;
        end
        pi = self.stim_sequence(si);
        self.stim_sequence_index = si;
        self.stim_parameter_index = pi;
    end
    
    function initStim(self)
    end
    
    function startStimulation(self, p_index)
        if nargin < 2 || isempty(p_index)
            p_index = self.stim_parameter_index;
        end
        
        % Put start code here%
        
        error('startStimulation was not defined in the subclass!');
    end
    
    function stopStimulation(self, advance, p_index)
        if nargin < 3 || isempty(p_index)
            p_index = self.stim_parameter_index;
        end
    
        % Put stop code here%
        
        if nargin < 2 || advance
            self.stimNextIndex();
        end
        
        error('stopStimulation was not defined in the subclass!');
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
end
    
end

