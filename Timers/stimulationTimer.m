classdef stimulationTimer < eventTimer
% stimulationTimer 
%   An eventTimer subclass that controls stimulation.
%   :self:          handle					A handle that points to the eventTimer object
%   :parent:		handle					The handles of master event timer
%   :subevents:		structure				Handles of subordinate event timers 
%   :name:			string					Name of the event timer
%   :timer_args:	structure				Arguments for the timers
%   :arguments:		structure				Containing user defined arguments
%   :variables:		structure				Containing user defined variables
%   :timestamps:	timestamps object		Timestamps for this event timer
%   :inputs:		structure of handles	Handles that link to large data locations
%   :outputs:		structure				A structure of user defined outputs
%   :plots:			structure				A structure of user defined plots
%   :current_timer:	double					The timer number in use
%   :timers:		structure of timers		The timers that are controlling the events
%
%   :on_duration:   double                  The duration of a train of stim
%   :off_duration:  double                  The intertrain pause between trains
%   :start_delay:   double                  The delay of the first stim train
%   :resume_delay:  double                  The pause before the analyses resume
%
%   :allow_stim:    boolean                 Allows stimulation to trigger
%   :allow_train:   boolean                 Determines if the next train will run
%   :allow_next:    boolean                 Determines if the next analysis will run
%   :stim_settings: struct                  The simulator settings
%
%   :stim_on:       boolean                 Indicates if the stimulation is active
%   :start_tic:     double                  The start of stim train
%   :stim_duration: double                  The maximum amount of stim allowed
%   :total_stim:    double                  The amound of stim that has occured
%   :train:         double                  The current train running
%   :total_trains:  double                  The total number trains to run                
%
%   :device:        object                  The device the stimulator will be using
%   :UI:            handles                 The UI to display information to

properties
    on_duration
    off_duration
    start_delay
    resume_delay
    
    allow_stim
    allow_train
    allow_next
    stim_settings
    sample_rate
    
    stim_on
    start_tic
    stim_duration
    total_stim
    train
    total_trains
    change
    
    device
    UI
end

methods
    %% ---- Methods ---- %%
    function self = stimulationTimer(name, device, on_duration, off_duration, total_trains, start_delay, resume_delay, allow_stim, stim_settings, inputs, args, pars, parent, subs)
    % stimulationTimer
    %   Initializes the stimulationTimer object
    %   Input
    %   :name:          string      The name of this stimulationTimer
    %   :device:        object      The device the stimulator will be using
    %   :on_duration:   double      The duration of a train of stim
    %   :off_duration:  double      The intertrain pause between trains
    %   :total_trains:  double      The total number trains to run
    %   :start_delay:   double      The delay of the first stim train
    %   :resume_delay:  double      The pause before the analyses resume
    %   :allow_stim:    boolean     Allows stimulation to trigger
    %   :inputs:        struct      A struct of the input objects
    %   :stim_settings: struct      The simulator settings
    %   :args:          structure	Arguments for the stimulation
    %   :pars:          structure   The Parameters for the timers
    %   :parent:        handle		Points to an object that controls this one
    %   :subs:          structure   Points to the objects which this one controls
    %   Output
    %   :self:          handle      A handle that points to the stimulationTimer object
        if nargin > 0
            wargs{1} = name;
            wargs{2} = struct;
            if nargin > 11
                wargs{3} = parent;
            end
            if nargin > 12 
                wargs{4} = subs;
            end
        else
            device = [];
            on_duration = 60;
            off_duration = 60;
            total_trains = 1;
            start_delay = 0;
            resume_delay = 60;
            allow_stim = false;
            stim_settings = [];
        end
        self@eventTimer(wargs{:});

        if nargin < 12
            pars.TimerFcn = {@self.stimulate};
            pars.StopFcn = {@self.stimulateEnd};
            pars.ExecutionMode = 'fixedRate';
            pars.BusyMode = 'queue';
            pars.StartDelay = start_delay;
            pars.Period = on_duration;
            pars.TasksToExecute = 2;
        end
        buildTimers(self, self.name, pars)

        self.device = device;
        self.auto_start = false;
        self.stim_settings = stim_settings;
        
        self.on_duration = on_duration;
        self.off_duration = off_duration;
        self.total_trains = total_trains;
        self.start_delay = start_delay;
        self.resume_delay = resume_delay;
        self.allow_stim = allow_stim;
        self.UI = [];
        
        self.stim_duration = 3600;
        self.stim_on = false;
        self.total_stim = 0;
        self.interruptable = false;
        self.allow_next = true;
        
        self.arguments = args;
        setInputs(self, inputs, [])
    end
    
    function varargout = stimulationParameters(self, varargin)
    % stimulationParameters
    %   Sets the stimulation parameters on the device, it wraps the device
    %   stimulationParameters
    %   Inputs
    %   :self:          handle      A handle that points to the stimulationTimer object
    %   :varargin:      many        All the parameters needed to setup the stimulator 
    %                               based on the device
    %   Outputs
    %   :varargin:      many        All outputs from the device stimulationParameters
        varargout = stimulationParameters(self.device, varargin);
    end
     
    function startSeries(self)
    % startSeries
    %   Starts a series of stimulation trains
    %   Inputs
    %   :self:          handle      A handle that points to the stimulationTimer object
        if self.allow_stim
            stopSubevents(self, true);
            if ~self.timestamps.zero
                if isfield(self.inputs, 'record_data')
                    self.timestamps.zero = self.inputs.record_data.timestamps.zero;
                else
                    self.timestamps.zero = 0;
                    self.timestamps.start_tic = tic;
                end
            end
            self.train = 0;
            self.allow_train = true;
            startNextTimer(self, true);
            try
                UItrainON(self);
            catch
            end
        else
            disp('Stimulation Triggered but stimulation is off.')
            if isfield(self.inputs, 'record_data')
                [~, a_ts] = self.inputs.record_data.collectData();
            else
                a_ts = [];
            end
            un_now = datetime();
            new_timestamp = self.beginTimestamp(a_ts, un_now);
            addTimestamp(self.timestamps, new_timestamp);
        end
    end
    
    function startStimulation(self)
    % startStimulation
    %   Starts stimulation on the device specified by the device property
    %   Input
    %   :self:          handle      A handle that points to this stimulationTimer object
        startStimulation(self.device);
        self.stim_on = true;
    end
    
    function stopStimulation(self)
    % stopStimulation
    %   Stops stimulation on the device specified by the device property
    %   Input
    %   :self:          handle      A handle that points to this stimulationTimer object
        stopStimulation(self.device);
        self.stim_on = false;
    end
    
    function [timestamp] = beginTimestamp(self, a_ts, un_now)
    % beginTimestamp
    %   Create a device timestamp then add beginning stimulation information
    %   Inputs
    %   :self:          handle      A handle that points to the stimulationTimer object
        if ~isempty(a_ts)
            [timestamp, ~] = self.device.alignedTimestamp(self.timestamps, a_ts.e_sample_number, self.sample_rate);
        end
        timestamp.settings = self.stim_settings;
        timestamp.clock_start = un_now;
        timestamp.clock_stop = [];
        timestamp.abrupt_stop = true;
    end
    
    function [timestamp] = endTimestamp(self, timestamp, end_sample, un_now)
    % endTimestamp
    %   Add endning stimulation information to a timestamp
    %   Inputs
    %   :self:          handle      A handle that points to the stimulationTimer object
        if ~isempty(end_sample)    
            e_sample_number = end_sample - self.timestamps.zero;
            e_adj_sn = e_sample_number - self.timestamps.adjustment;
            e_seconds = e_sample_number / self.device.sample_rate;

            timestamp.e_adj_sn = e_adj_sn;
            timestamp.e_seconds = e_seconds;
            timestamp.e_sample_number = e_sample_number;
        end
        timestamp.clock_stop = un_now;
    end
    
    function UIstartStim(self, un_now)
        UIindicatorON(self);
%         if isfield(self.inputs, 'record_data')
%             self.UImarkStimStart(un_now);
%         end
    end
    
    function UIindicatorON(self)
        if ~isempty(self.UI)
            handles = guidata(self.UI);
            stim_str = sprintf('%duA Stimulation ON ', self.stim_settings.amp);
            set(handles.stimState, 'string', stim_str,'BackgroundColor', 'r');
            guidata(self.UI, handles);
        end
    end
    
    function UImarkStimStart(self, un_now)
    % uiStartStim
    %   Changes the UI so it displays that stimulation is on
    %   Inputs
    %   :self:          handle      A handle that points to the stimulationTimer object
    %   :now:           double      The time that has passed since the start of 
    %                               the trial in [s]
        record_data = self.inputs.record_data;
        
        for i = 1:length(record_data.plots)
            parent = record_data.plots(i).subplot;
            if isfield(record_data.plots(i), 'stim_start')
                line_num = length(record_data.plots(i).stim_start)+1;
            else
                line_num = 1;
            end
            record_data.plots(i).stim_start(line_num) = line([now un_now], [-1000 1000],'Parent',parent,'Color','r');
        end
    end
    
    function UItrainON(self)
        if ~isempty(self.UI)
            handles = guidata(self.UI);
            stim_str = sprintf('Train Stimulation ON');
            set(handles.trainState, 'string', stim_str,'BackgroundColor', 'r');
            guidata(self.UI, handles);
        end
    end
    
    function UIstopStim(self, un_now)
    % uiStopStim
    %   Changes the UI so it displays that stimulation is off
    %   Inputs
    %   :self:          handle      A handle that points to the stimulationTimer object
    %   :now:           double      The time that has passed since the start of 
    %                               the trial in [s]
        UIindicatorOFF(self);
%         if isfield(self.inputs, 'record_data')
%             self.UImarkStimStop(un_now);
%         end
    end
    
    function UIindicatorOFF(self)
         if ~isempty(self.UI)
            handles = guidata(self.UI);
            if self.total_stim < self.stim_duration
                set(handles.stimState, 'string','Stimulation OFF','BackgroundColor',[0.86 0.86 0.86]);
            else
                set(handles.stimState, 'string','Stimulation OFF Maximum Reached','BackgroundColor',[0.86 0.86 0.86]);
            end
            guidata(self.UI, handles);
        end
    end
    
    function UImarkStimStop(self, un_now)
        record_data = self.inputs.record_data;
        
        for i = 1:length(record_data.plots)
            parent = record_data.plots(i).subplot;
            if isfield(record_data.plots(i), 'stim_end')
                line_num = length(record_data.plots(i).stim_end)+1;
            else
                line_num = 1;
            end
            record_data.plots(i).stim_end(line_num) = line([now un_now], [-1000 1000],'Parent',parent,'Color','b');
        end
    end
    
    function UItrainOFF(self)
        if ~isempty(self.UI)
            handles = guidata(self.UI);
            set(handles.trainState, 'string','Train OFF','BackgroundColor',[0.86 0.86 0.86]);
            guidata(self.UI, handles);
        end
    end
    
    %% ---- Timer Functions ---- %%
    function stimulate(obj, event, time, self)
    % stimulate
    %   Controls when to start and stop stimulation
    %   Input
    %   :object:    handle      The timer object
    %   :event:     handle      An unused Matlab feature
    %   :time:      handle      An unused reference 
    %   :self:      handle      A handle that points to the stimulationTimer object
        info_log = self.inputs.info_log;
        if isfield(self.inputs, 'record_data')
            record_data = self.inputs.record_data;
        end
            
        if ~self.stim_on && (self.total_stim < self.stim_duration)
            % ---- Start Stimulation ---- %
            if self.allow_stim
                startStimulation(self);
            end
            % ---- Create Timestamp ---- %
            self.stim_on = true;
            
            self.start_tic = tic;
            if isfield(self.inputs, 'record_data')
                [~, ts] = collectData(record_data);
            else
                ts = [];
            end
            r_now = toc(self.timestamps.start_tic);
            un_now = datetime();

            new_timestamp = self.beginTimestamp(ts, un_now);
            addTimestamp(self.timestamps, new_timestamp);
            
            % ---- Pause Saving ---- %
            if isfield(self.subevents, 'saver')
                self.subevents.saver.allow_save = false;
            end
            
            % ---- UI ---- %
            if isfield(new_timestamp, 'b_seconds')
                info = sprintf('Stimulating at %.2f seconds for %.2f seconds.', new_timestamp.b_seconds, self.on_duration);
            else
                info = sprintf('Stimulating for %.2f seconds.', self.on_duration);
            end
            append(info_log, info, true, true);
            UIstartStim(self, r_now)
            
        elseif self.stim_on
            % ---- Stop Stimulation ---- %
            stopStimulation(self);
            
            % ---- Create Timestamp ---- %
            duration = toc(self.start_tic);
            un_now = datetime();
            r_now = toc(self.timestamps.start_tic);
            if isfield(self.inputs, 'record_data')
                [~, ts] = collectData(record_data);
            else
                ts.e_sample_number = [];
            end
            
            last_ts = returnLastStamp(self.timestamps);
            new_timestamp = endTimestamp(self, last_ts, ts.e_sample_number, un_now);
            new_timestamp.abrupt_stop = false;
            setLastStamp(self.timestamps, new_timestamp);
            
            self.total_stim = self.total_stim + duration;
            
            % ---- UI ---- %
            if isfield(new_timestamp, 'b_seconds')
                info = sprintf('Stoping Stimulation at %.2f seconds.', (duration + new_timestamp.b_seconds));
            else
                info = sprintf('Stoping Stimulation at %.2f seconds.', (duration));
            end
            append(info_log, info, true, true);
            UIstopStim(self, r_now);
            
            stopTimers(self, false);
        else
            stopTimers(self, false);
        end
    end
    
    function stimulateEnd(obj, event, time, self)
    % stimulateEnd
    %   Controls the end of stimulation, when to start the next stimulation
    %   or the next analysis
    %   Input
    %   :object:    handle      The timer object
    %   :event:     handle      An unused Matlab feature
    %   :time:      handle      An unused reference 
    %   :self:      handle      A handle that points to the stimulationTimer object
        info_log = self.inputs.info_log;
        if isfield(self.inputs, 'record_data')   
            record_data = self.inputs.record_data;
        end
        if isfield(self.inputs, 'trial')
            trial = self.inputs.trial;
        end
        
        if self.stim_on
            % ---- Stop Stimulation ---- %
            stopStimulation(self);
            
            % ---- Create Timestamp ---- %
            duration = toc(self.start_tic);
            un_now = datetime();
            r_now = toc(self.timestamps.start_tic);
            if isfield(self.inputs, 'record_data')
                [~, ts] = collectData(record_data);
            else
                ts.e_sample_number = [];
            end
            
            last_ts = returnLastStamp(self.timestamps);
            new_timestamp = endTimestamp(self, last_ts, ts.e_sample_number, un_now);
            setLastStamp(self.timestamps, new_timestamp);
            
            self.total_stim = self.total_stim + duration;
            
            % ---- UI ---- %
            if isfield(new_timestamp, 'b_seconds')
                info = sprintf('Stoping Stimulation at %.2f seconds.', (duration + new_timestamp.b_seconds));
            else
                info = sprintf('Stoping Stimulation at %.2f seconds.', (duration));
            end
            append(info_log, info, true, true);
            UIstopStim(self, r_now);
        end
        
        self.train = self.train + 1;
        if self.allow_train && self.train < self.total_trains
            % ---- Start Next Train ---- %
            next_args.StartDelay = self.off_duration;
            setNextTimer(self, next_args);
            startNextTimer(self, false);
            
            append(info_log, sprintf('Starting next stimulation in %.2f seconds.', (self.off_duration)), true, true);
        elseif self.allow_next && isfield(self.inputs, 'trial') && trial.on
            % ---- Resume Analyses ---- %
            sub_names = fieldnames(self.subevents);
            for index = 1:length(sub_names)
                next_args.StartDelay = self.resume_delay + self.subevents.(sub_names{index}).inherent_delay;
                setNextTimer(self.subevents.(sub_names{index}), next_args);
                startNextTimer(self.subevents.(sub_names{index}), true);
            end
            
            % ---- Resume Saving ---- %
            if isfield(self.subevents, 'saver')
                self.subevents.saver.allow_save = true;
                if self.subevents.saver.skipped
                    saveOut(self.subevents.saver)
                end
            end
            
            note = {sprintf('Delaying next analyses by %0.2f seconds.',self.resume_delay), 'Streaming...'};
            append(info_log, note, true, true);
            try
                UItrainOFF(self);
            catch
            end
        elseif isfield(self.inputs, 'trial')
            try
                UItrainOFF(self);
            catch
            end
            saveQuit(trial);
        else
            try
                UItrainOFF(self);
            catch
            end
        end   
    end
    
end    
end


