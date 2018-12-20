classdef TDTdevice < Device
% TDTdevice
%   An object that communicates with the TDT, retains relative information, and controls it.
%
%   The TDT has multiple methods of controlling its features. This device object 
%   organizes those methods and allows selection of the prefered method. 
%   When constructing this the type of DAQ, server, and stimulation trigger
%   can be set.
%
%   Properties
%   Fixed Sample Rates    
%   :fs_25kH:               (double)    The exact sample rate of the 25 kHz 
%   :fs_3kH:                (double)    The exact sample rate of the 3 kHz
%
%   Server
%   :server_type:           (double)    A numeric representing the type of 
%                                       server being used to communicate
%                                       with the TDT system. 0 = None, 
%                                       1 = Synapse, 2 = OpenEx
%   :synapse:               (object)    The SynapseAPI object controlling
%                                       the TDT system.
%   :openex:                (object)    The TDTlive object controlling the
%                                       TDT system.
%   :server:                (object)    The current server object being
%                                       used, either Synapse or OpenEx.
%
%   OpenEx
%   :start_time:            (double)    The start time of the TDT recording.
%   :duration:              (double)    The amount of time elapsed since
%                                       the start of the recording in seconds.
%   :mat_sec_s:             (double)    The offset of start of the matlab 
%                                       recording reltive to the TDT start 
%                                       in seconds.
%   :mat_samp_s:            (double)    The offset of start of the matlab 
%                                       recording reltive to the TDT start 
%                                       in samples.
%   :last_delay:            (double)    The approximate time delay of the
%                                       data being recorded to being
%                                       available in Matlab.
%     
%   DAQ Type
%   :DAQ_type:              (double)    A numeric representing the type of 
%                                       DAQ being used. 0 = None, 
%                                       1 = PO8e, 2 = Tank Streams
%   :PO8e:                  (object)    The PO8e_card object acquiring data.
%   :streamer:              (object)    The server object acquiring data.
%     
%   Stimulation Trigger
%   :trigger:               (double)    A numeric representing the method 
%                                       of triggering stimulation. 0 = None, 
%                                       1 = UDP, 2 = Server
%    
%   Server Stimulation Circuit Variables
%   :s_buffer_total_n:      (char)      Number of channels in the stim buffer
%   :s_buffer_samples_n:    (char)      Number of samples in channel of the
%                                       stimulation buffer.
%   :s_buffer_n:            (char)      The stimuation buffer.
%   :s_active_n:            (char)      Boolean for activating stimulation.
%     
%   Trial Properities
%   :sample_rates:          (matrix)    A matrix of the sample rates for
%                                       each Wav.


properties
    % Fixed Sample Rates %
    fs_25kH = 24414.0625;
    fs_3kH  = 3051.7578125;
    
    % Server %
    server_type
    synapse
    openex
    server
    
    % OpenEx %
    server_fig
    start_time
    duration
    mat_sec_s
    mat_samp_s
    last_delay
    
    % DAQ %
    DAQ_type
    PO8e
    streamer
    
    % Stimulation Trigger %
    trigger
    UDP
    s_header = 1
    
    % Server Stimulation Circuit Variables %
    s_buffer_total_n = 'RZ2.stim_buf_size_samp'; 
    s_buffer_samples_n = 'RZ2.stim_time_samp';
    s_buffer_n = 'RZ2.stim_data_buf';
    s_active_n = 'RZ2.stim_go';
    
    % Trial Properities %
    sample_rates
end

methods
    %% ---- Methods ---- %%
    function self = TDTdevice(name, DAQ_type, server_type, trigger)
    % TDTdecive
    %   Intitializes a TDTdevice object. None of the parameters are required.
    %   
    %   Input
    %   :name:          (string)    The name of the server connecting to.
    %                               The default is "Local". 
    %   :DAQ_type:      (string)    The type of DAQ to be used.  
    %                               The default is "PO8e".
    %   :server_type:   (string)    The type of server to be used.
    %                               The default is "None".
    %   :trigger:       (string)    The stimulation trigger to use.
    %                               The default is "UDP".
    %   Output
    %   :self:          (handle)    This TDTdevice object.
        % Assign Server Name %
        if nargin > 0
            self.name = name;
        else
            self.name = 'Local';
        end
        
        % Assign Defaults %
        self.duration = 0;
        self.last_delay = [];
        
        % DAQ Setup %
        if nargin > 1
            if strcmp(DAQ_type, 'None')
                self.DAQ_type = 0;
            elseif strcmp(DAQ_type, 'PO8e')
                initPO8e(self);
                self.DAQ_type = 1;
            elseif strcmp(DAQ_type, 'Tanks')
                initTankStreamer(self);
                self.DAQ_type = 2;
            else
                error('%s is not a DAQ Type.', DAQ_type)
            end
        else
            try
                initPO8e(self);
                self.DAQ_type = 1;
            catch
                warning('PO8e not initialized. This TDTdevice has no DAQ.')
                self.DAQ_type = 0;
            end
        end
        
        % Server Setup %
        if nargin > 2
            if strcmp(server_type, 'None')
                self.server_type = 0;
            elseif strcmp(server_type, 'Synapse')
                initSynapse(self);
                self.server_type = 1;
            elseif strcmp(server_type, 'OpenEx')
                initOpenEx(self);
                self.server_type = 2;
            else
                error('%s is not a Server Type.', server_type);
            end
        else
            self.server_type = 0;
            self.max_fs = self.fs_25kH;
            self.sample_rate = self.fs_3kH;
        end
        
        % Stimulation Trigger %
        if nargin > 3
            if strcmp(trigger, 'UDP')              
                try
                    self.initUDP()
                    self.trigger = 1;
                catch
                    disp('Stimulation Trigger Type set to None');
                    self.trigger = 0;
                end
            elseif strcmp(trigger, 'Server')
                self.trigger = 2;
            elseif strcmp(trigger, 'None')
                self.trigger = 0;
            else
                error('%s is not a Stimulation Trigger Type.', trigger);
            end
        else
            try
                self.initUDP()
                self.trigger = 1;
            catch ME
                warning(ME.message);
                disp('Stimulation Trigger Type set to None');
                self.trigger = 0;
            end
        end
        
        % Set self %
        self.self = self;
    end
    
    function delete(self)
    % delete
    %   The delete function when the object is deleted. This ensures any
    %   resources are released when this object is deleted.
        if self.DAQ_type == 1
            self.releasePO8e(true);
        end
        if self.trigger == 1
            self.UDP.delete();
        end
        if ~empty(self.server_fig)
            close(self.server_fig)
        end
    end
    
    % Server Control %
    function buffer = createBiphasicBuffer(self, tc, amp, pw, ipd, f, dur, sr)
    % createBiphasicBuffer
    %   Create biphasic square wave signals to be used for stimulation
    %   Inputs
    %   :self:          handle      The TDT device object
    %   :tc:            double      The number of biphasic square wave signals to create
    %   :amp:           double      The amplitude of the singal in [uA]
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
    
    function [returns] = initTDTstimBuffer(self, buffer)
    % initTDTstimBuffer
    %   Initializes the stimulation buffer for the TDT
    %   Input
    %   :self:          handle      The TDT device object
    %   :buffer:        matrix      The row wise singals the stimulator will output
    %   Output
    %   :returns:       vector      The what is in the stimulator buffer after
    %                               loading the new signal in 
        % Reorganize the buffer into a vector %
        [channels, buffer_len] = size(buffer);
        total = channels*buffer_len;
        buffer = buffer(:)';
        
        % Send the buffer to the TDT %
        if ~self.server.SetTargetVal(self.s_buffer_total_n, total)
            warning('Could not load buffer.');
        end
        self.server.SetTargetVal(self.s_buffer_samples_n, buffer_len);
        self.server.WriteTargetVEX(self.s_buffer_n, 0, 'F32', buffer);
        
        % Return the buffer in the TDT %
        returns = self.server.ReadTargetVEX(self.s_buffer_n, 0,total, 'F32', 'F32'); 
    end
    
    function returns = loadServerStimBuffer(self, parameters)
    % loadBuffer
    %   Create biphasic square wave signals and assign them as the stimulation signal
    %   Inputs
    %   :self:          handle      The TDT device object
    %   :parameters:    vector      The general stimulation parameters in vector form
    %   Outputs
    %   :returns:       vector      The what is in the stimulator buffer after
    %                               loading the new signal in
    % [StimDur(ms) StimGain PusleCount PulsePeriod LevelA DurA LevelB DurB levelC DurC Chan1 Chan2]
        tc = 1;
        amp = parameters(5);
        pw = parameters(6);
        f = parameters(4);
        dur = parameters(1);
        if parameters(10) == 0
            ipd = 0;
        else
            ipd = parameters(8);
        end
    
        buffer = createBiphasicBuffer(self, tc, amp, pw, ipd, f, dur);
        returns = initTDTstimBuffer(self, buffer);
    end
    
    function startServerStim(self)
        if self.server_type == 2
            self.openex.SetTargetVal(self.s_active_n, 1);
        else
            self.synapse.setParameterValues('stim','z_pulse',1);
        end
    end
    
    function stopServerStim(self)
        if self.server_type == 2
            self.openex.SetTargetVal(self.s_active_n, 0);
        else
            self.synapse.setParameterValues('stim','z_pulse',0);
        end
    end
    
    % Synapse %
    function initSynapse(self)
        self.synapse = SynapseAPI();
        self.server = self.synapse;
    end
    
    function result = isExperiment(self, name)
        exps = self.synapse.getKnownExperiments();
        result = ismember(name, exps);
    end
    
    function result = setExperiment(self, name)
        result = self.synapse.setCurrentExperiment(name);
        if result == 0
            if isExperiment(self, name) == 0
                warning([name ' is not an Experiment in Synapse'])
            else
                warning('Synapse Experiment not set')
            end
        else
            self.sample_rates = self.synapse.getSamplingRates();
        end
    end
    
    % OpenEx %
    function initOpenEx(self)
        self.server_fig = figure('Visible', 'off');
        self.openex = actxcontrol('TDevAcc.X', 'Parent', self.server_fig);
        
        self.s_buffer_total_n = 'RZ2.stim_buf_size_samp'; 
        self.s_buffer_samples_n = 'RZ2.stim_time_samp';
        self.s_buffer_n = 'RZ2.stim_data_buf';
        self.s_active_n = 'RZ2.stim_go';
        self.max_fs = self.fs_25kH;
        
        if ~self.openex.ConnectServer(self.name)
            warning('OpenEx Server could not connect.')
        end
        self.server = self.openex;
    end
    
    % UDP %
    function initUDP(self) 
        self.UDP = TDTudp();
    end
    
    % PO8e Data Streamer %
    function [PO8e] = initPO8e(self)
        PO8e = PO8e_card();
        self.PO8e = PO8e;
    end
    
    function connectPO8e(self)
        self.PO8e.connect();
    end
    
    function releasePO8e(self, verb)
        if nargin < 2
            verb = false;
        end
        self.PO8e.release(1:self.PO8e.card_count, verb);
    end
    
    function PO8eStartCollecting(self)
        self.PO8e.startCollection();
    end
    
    function [raw_channels, ts] = getPO8eData(self, IDs, timestamps)
        numSamples = self.PO8e.collectData(1:self.PO8e.card_count, false);
        
        raw_channels = cell(1,length(IDs));
        for i = 1:length(IDs)
            c_num = IDs{i,3};
            card = fix((c_num-1)/ 256) + 1;
            chan = rem((c_num-1), 256)+ 1;
            raw_channels{i} = double(self.PO8e.Data{card}(chan, 1:numSamples));
        end
        % Calcuate Output Information %
        ts = PO8eDataTimestamp(self, timestamps, numSamples, self.sample_rate);
    end
    
    % Tank Data Streamer %
    function [streamer] = initTankStreamer(self)
    % initStreamer
    %   Intitializes the TDT data store streamer and saves it in the TDT device.
    %   Input
    %   :self:          handle      The TDT device object
    %   Output
    %   :steamer:       object      The TDT data store streaming object
        try
            % Connect to Steamer%
            disp('Connecting to TDT data stores...')
            if self.server_type == 1
                streamer = SynapseLive();
            else
                streamer = TDTlive();
            end
            pause(0.1);

            % Set the streamer Parameters %
            streamer.TYPE = {'streams'};
            streamer.VERBOSE = false;

            % Update the data %
            streamer.update;
            pause(0.1);

            % Assign the TDT device properties %
            self.sample_rate = streamer.data.streams.Wav1.fs;
            self.start_time = datetime([streamer.data.info.date ' ' streamer.data.info.starttime]);
            self.streamer = streamer;
        catch
            % If connecting to the Data Store Streamer fails then throw a warning
            warning('Could not connect to TDT data stores. Run initStreamer(obj) to retry.')
            self.data_streamer = [];
            self.start_time = [];
            self.sample_rate = NaN;
        end
    end
    
    function tankStartCollection(self)
    % tankStartCollection
    %   Intitializes Data Collection of the data store streamer.
    %   Input
    %   :self:          handle      The TDT device object
        self.streamer.update;
        self.mat_sec_s = self.streamer.T1;
        self.mat_samp_s = floor(self.mat_sec_s*self.sample_rate);
    end
    
    function [raw_channels, ts] = getTankData(self, IDs, timestamps)
    % getTankData
    %   Get the data from the data store streamer since the initialization
    %   or the last getTankData call
    %   Inputs
    %   :self:          handle              The TDT device object
    %   :IDs:           cell array          Array of the channnel IDs to get data from 
    %   Outputs
    %   :raw_channels:          cell array          The data from all of the channels in a cell array
    %   :sample_rate:           double              The sample rate of data
    %   :samples_perchannel:    double              The number of samples recorded from each channel
    %   :TDT_last_sample:       double              The absolute sample number of the last sample in the new data
        % Request the data from the TDT %
        self.data_streamer.update;
        for index = 1:length(IDs)
            raw_channels{index} = double(self.streamer.data.streams.(char(IDs{index}(1))).data(cell2mat(IDs{index}(2)),:));
        end
        
        start = self.streamer.T1;
        finish = self.streamer.T2;
        
        % Calcuate Output Information %
        samples = length(self.streamer.data.streams.Wav1.data);
        sample_rate = self.streamer.data.streams.Wav1.fs;
        ts = tankDataTimestamp(self, timestamps, start, finish, samples, sample_rate);
        
        self.duration = self.streamer.CURRTIME;
        t = datetime('now');
        self.last_delay = t - (self.start_time + seconds(self.duration));    
    end
    
    % ---- Universal Device Functions ---- %
    function channels = channelStruct(self)
        channels.names = {'First','Second','Third','Fourth'};
        channels.wav_names = {'Wav1','Wav2','Wav3','Wav4','ANIN'};
        channels.IDs = {};
        channels.chans = [1 2 3 4];
        channels.type_names = {'t_Hipp','r_Hipp','t_Amyg','r_Amyg','Reference','Stim'};
        channels.record_i = [1 2];
        channels.w_values = [1 1 1 1];
        channels.t_values = [7 7 7 7];
    end
    
    function channels = selectChannels(self, varargin)
        channels = TDT_selectChannels(varargin);
    end
    
    function initDataCollection(self)
        if self.DAQ_type == 1
            PO8eStartCollecting(self);
        elseif self.DAQ_type == 2
            tankStartCollection(self);
        end
    end
    
    function shutdown(self)
        if self.DAQ_type == 1
            self.releasePO8e();
        end
    end
    
    function [raw_channels, ts] = getData(self, IDs, timestamps)
        if self.DAQ_type == 1
            [raw_channels, ts] = getPO8eData(self, IDs, timestamps);
        elseif self.DAQ_type == 2
            [raw_channels, ts] = getTankData(self, IDs, timestamps);
        end
    end
    
    function returns = addStimParameters(self, parameters)
    % stimulationParameters
    % [StimDur(ms) StimGain PusleCount PulsePeriod LevelA DurA LevelB DurB levelC DurC Runs Samp...
    %  Mute-A Mute-B A1 A2 A3 A4 B1 B2 B3 B4 User-1 User2]
        self.stim_parameter_array(end+1,:) = parameters;
        if self.trigger == 2
            returns = self.loadServerStimBuffer(parameters);
        end
    end
    
    function initStim(self)
        if self.trigger == 1
            self.stopStimulation(false);
        end
    end
    
    function startStimulation(self, p_index)
    % startStimulation
    %   Starts stimulation on the TDT
    %   Input
    %   :self:          handle      The TDT device object
        if nargin < 2 || isempty(p_index)
            p_index = self.stim_parameter_index;
        end
    
        if self.trigger == 0
            disp('No stimulation trigger set. Nothing happened.')
        elseif self.trigger == 1
            packet = self.stim_parameter_array(p_index,:);
            self.UDP.sendDatagram([self.s_header 1 packet]);
        elseif self.trigger == 2
            self.startServerStim();
        end
    end
    
    function stopStimulation(self, advance, p_index)
    % startStimulation
    %   Stops stimulation on the TDT
    %   Input
    %   :self:          handle      The TDT device object
        if nargin < 3 || isempty(p_index)
            p_index = self.stim_parameter_index;
        end
    
        if self.trigger == 0
            disp('No stimulation trigger set. Nothing happened.')
        elseif self.trigger == 1
            packet = self.stim_parameter_array(p_index,:);
            self.UDP.sendDatagram([self.s_header 0 packet]);
        elseif self.trigger == 2
            self.stopServerStim();
        end
        
        if nargin < 2 || advance
            self.stimNextIndex();
        end
    end
    
    % ---- Timestamps ---- %
    function [new_timestamp, current_index] = makeTimestamp(~, timestamps, type, samples_perchannel, e_TDT_sn, start_offset, sample_rate)
    % makeTimestamp
    %   Creates a timestamp based on sample number and type.
    %   Types of timestamp: 'record_data' 'time_aligned' 'unaligned'
    %   record_data: creates a timestamp for record data     
    %   time_aligned: creates a timestamp based on the relative zeroing of the timestamps object
    %   unaligned: creates a timestamp based only on input beginning sample number
    %   Inputs
    %   :self:                  handle              The TDT device object
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

        b_TDT_sn = e_TDT_sn - samples_perchannel + 1;
        dropped_samples = NaN;
        if strcmp(type,'record_data')
            if current_stamp-1 == 0
                b_sample_number = 1;
                e_sample_number = b_sample_number + samples_perchannel - 1;
                timestamps.zero = b_TDT_sn;
                previous_sample = 0;
            else
                b_sample_number = b_TDT_sn - timestamps.zero + 1;
                e_sample_number = b_sample_number + samples_perchannel - 1;
                previous_sample = timestamps.stamps.list(current_index-1).e_sample_number;
            end
            dropped_samples = b_sample_number - previous_sample - 1;
        elseif strcmp(type,'time_aligned')
            b_TDT_sn = e_TDT_sn - start_offset + 1;
            b_sample_number = b_TDT_sn - timestamps.zero;
            e_sample_number = e_TDT_sn - timestamps.zero;
        else
            b_sample_number = e_TDT_sn;
            e_sample_number = e_TDT_sn;
        end

        b_adj_sn = b_sample_number - timestamps.adjustment;
        e_adj_sn = e_sample_number - timestamps.adjustment;
        b_seconds = (b_sample_number-1)/sample_rate;
        e_seconds = e_sample_number/sample_rate;

        % Create Timesamp Structure
        new_timestamp.b_TDT_sn = b_TDT_sn;
        new_timestamp.e_TDT_sn = e_TDT_sn;
        new_timestamp.b_adj_sn = b_adj_sn;
        new_timestamp.e_adj_sn = e_adj_sn;
        new_timestamp.number = current_stamp;
        new_timestamp.b_seconds = b_seconds;
        new_timestamp.e_seconds = e_seconds;
        new_timestamp.b_sample_number = b_sample_number;
        new_timestamp.e_sample_number = e_sample_number;
        new_timestamp.dropped_samples = dropped_samples; 
    end
    
    function [ts, current_index] = alignedTimestamp(self, timestamps, e_sn, sample_rate, offset)
    % alignedTimestamp
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
        if nargin < 4 || isempty(sample_rate)
            sample_rate = self.sample_rate;
        end
        
        if nargin < 5
            offset = 0;
        end
    
        % Get Timestamp Number
        current_index = timestamps.stamp_index + 1;
        current_stamp = timestamps.stamp_number + 1;
        
        b_sample_number = e_sn - offset +1;
        
        % Create Timesamp Structure
        ts.number = current_stamp;
        ts.b_adj_sn = b_sample_number - timestamps.adjustment;
        ts.e_adj_sn = e_sn - timestamps.adjustment;
        ts.b_seconds = (b_sample_number-1)/sample_rate;
        ts.e_seconds = e_sn/sample_rate;
        ts.b_sample_number = b_sample_number;
        ts.e_sample_number = e_sn;
    end
    
    function [ts, current_index] = PO8eDataTimestamp(self, timestamps, numSamples, sample_rate)
    % PO8eDataTimestamp
    %   Creates a timestamp based on sample number and type.
    %   Types of timestamp: 'record_data' 'time_aligned' 'unaligned'
    %   record_data: creates a timestamp for record data     
    %   time_aligned: creates a timestamp based on the relative zeroing of the timestamps object
    %   unaligned: creates a timestamp based only on input beginning sample number
    %   Inputs
    %   :self:                  handle              The TDT device object
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
        
        if current_stamp == 1
            b_sample_number = 1;
            e_sample_number = b_sample_number + numSamples - 1;
        else
            previous_sample = timestamps.stamps.list(current_index-1).e_sample_number;
            b_sample_number = previous_sample + 1;
            e_sample_number = b_sample_number + numSamples - 1;
        end

        % Create Timesamp Structure
        ts.number = current_stamp;
        ts.b_adj_sn = b_sample_number - timestamps.adjustment;
        ts.e_adj_sn = e_sample_number - timestamps.adjustment;
        ts.b_seconds =(b_sample_number-1)/sample_rate;
        ts.e_seconds = e_sample_number/sample_rate;
        ts.b_sample_number = b_sample_number;
        ts.e_sample_number = e_sample_number; 
    end
    
    function ts = tankDataTimestamp(self, timestamps, start, stop, samples, sample_rate)
        current_index = timestamps.stamp_index + 1;
        current_stamp = timestamps.stamp_number + 1;
        prev_ts = timestamps.stamps.list(current_index-1);
        
        b_seconds = start - self.mat_sec_s;
        e_seconds = stop - self.mat_sec_s;
        if current_stamp-1 == 0
            b_sample_number = 1;
            e_sample_number = samples;
            timestamps.zero = self.mat_samp_s;
        else
            previous_sample = prev_ts.e_sample_number;
            b_sample_number = previous_sample + 1;
            e_sample_number = previous_sample + samples; 
        end
        prev_sec = prev_ts.TDT_es;
        dis = start - prev_sec;
        if dis == 0
            dps = 0;
        else
            dps = dis*sample_rate;
        end
        
        ts.number = current_stamp;
        ts.b_adj_sn = b_sample_number - timestamps.adjustment;
        ts.e_adj_sn = e_sample_number - timestamps.adjustment;
        ts.b_seconds = b_seconds;
        ts.e_seconds = e_seconds;
        ts.b_sample_number = b_sample_number;
        ts.e_sample_number = e_sample_number;
         
        ts.TDT_bs = start;
        ts.TDT_es = stop;
        ts.b_TDT_sn = self.mat_samp_s + b_sample_number;
        ts.e_TDT_sn = self.mat_samp_s + e_sample_number;
       
        ts.dropped_samples = dps;
    end
end
    
end