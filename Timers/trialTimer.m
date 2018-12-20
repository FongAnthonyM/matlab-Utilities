classdef trialTimer < eventTimer
% trialTimer 
%   An eventTimer subclass that specifically controls other eventTimers for timed interactions.
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
%   :duration:      double                  The duration of the trial in seconds
%   :on:            boolean                 Indicates if the trial is running
%   :ECoG:          ECoGstruct              An object with all the data
%   :info_log:      infoLog                 An object take logs events

properties
    duration
    on
    
    ECoG
    info_log
end

methods
    %% ---- Methods ---- %%
    function self = trialTimer(info_log, ECoG, args, duration, pars, parent, subs)
    % trialTimer 
    %   Initializes the trialTimer object
    %   Input
    %   :duration:      double          The total duration of the trial in [s]
    %   :ECoG:          ECoGstruct      An object with all the data
    %   :info_log:      infoLog         An object take logs events       
    %   :args:          structure       Arguments for the analyses
    %   :pars:          structure       The Parameters for the timers
    %   :parent:        handle          Points to an object that controls this one
    %   :subs:          structure       Points to the objects which this one controls
    %   Output
    %   :self:          handle          A handle that points to the trialTimer object
        if nargin > 0
            wargs{1} = 'trial';
            wargs{2} = struct;
            if nargin > 5 
                wargs{3} = parent;
            end
            if nargin > 6 
                wargs{4} = subs;
            end
        else
            duration = 60;
            ECoG = ECoGstruct;
            info_log = infoLog;
        end
        self@eventTimer(wargs{:});
        
        if nargin < 6
            pars.StartFcn = {@self.startAll};
            pars.TimerFcn = {@self.blank};
            pars.StopFcn = {@self.stopAll};
            pars.ExecutionMode = 'singleShot';
            pars.BusyMode = 'drop';
            pars.StartDelay = duration;
            pars.TasksToExecute = 1;
        end
        buildTimers(self, self.name, pars)
        
        self.duration = duration;
        self.on = false;
        self.ECoG = ECoG;
        self.info_log = info_log;
            
        self.arguments = args;
    end
    
    function saveQuit(self)
    % saveQuit
    %   Saves the data
    %   Input
    %   :self:      handle      A handle that points to the trialTimer object
        args = self.arguments;
        ECoG = self.ECoG;
        info_log = self.info_log;
        
        sub_names = fieldnames(self.subevents);
        for index = 1:length(sub_names)
            child = self.subevents.(sub_names{index});
            all_timestamps.(child.name) = child.timestamps;
        end
        
        saveTrial(args.save_path, args.patient_ID, args.trial_name, ECoG, args, all_timestamps, info_log);
    end
    
    %% ---- Timer Functions ---- %%
    function startAll(obj, event, time, self)
    % startAll
    %   The first function to be run by timers which checks if there will
    %   be any saving done
    %   Input
    %   :object:    handle      The timer object
    %   :event:     handle      An unused Matlab feature
    %   :time:      handle      An unused reference 
    %   :self:      handle      A handle that points to the trialTimer object
        self.on = true;

        initRecordData(self.subevents.record_data);
        start_tic = tic;
        beginning = clock;
        self.timestamps.beginning = beginning;
        self.timestamps.start_tic = start_tic;
        
        sub_names = fieldnames(self.subevents);
        for index = 1:length(sub_names)
            child = self.subevents.(sub_names{index});
            child.timestamps.beginning = beginning;
            child.timestamps.start_tic = start_tic;
        end
        
        if isfield(self.subevents,'stimulator')
            self.subevents.stimulator.device.initStim();
        end
        
        startSubevents(self, true);
    end

    function blank(obj, event, time, self)
    % blank
    %   An empty function that allows a timer to be made without a TimerFcn
    %   Input
    %   :object:    handle      The timer object
    %   :event:     handle      An unused Matlab feature
    %   :time:      handle      An unused reference 
    %   :self:      handle      A handle that points to the trialTimer object
    end

    function stopAll(obj, event, time, self)
    % stopAll
    %   Stops all the trial and all subevents
    %   Input
    %   :object:    handle      The timer object
    %   :event:     handle      An unused Matlab feature
    %   :time:      handle      An unused reference 
    %   :self:      handle      A handle that points to the trialTimer object
        stopSubevents(self, true);
        self.on = false;
       
        saveQuit(self)
    end
end
    
end

