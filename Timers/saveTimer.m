classdef saveTimer < eventTimer
% recordTimer 
%   An eventTimer subclass that saves and clears memory periodicly.
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
%   :period:        double                  The period of the saveTimer in [s]
%   :allow_save:    boolean                 Allow saving or not
%   :skip:          boolean                 Skip the next save or not
%   :skipped:       boolean                 Shows if the last save was skipped
%   :hold:          double                  The time hold before clearning data

properties
    info_log
    ECoG
    
    period
    allow_save
    skip
    skipped
    
    hold
end

methods
    %% ---- Methods ---- %%
    function self = saveTimer(info_log, ECoG, period, hold, args, pars, parent, subs)
    % saveTimer 
    %   Initializes the saveTimer object
    %   Input
    %   :period:        double      The period of the saveTimer in [s]
    %   :hold:          double      The time hold before clearning data
    %   :inputs:        struct      A struct of the input objects
    %   :args:          structure	Arguments for the analyses
    %   :vars:          structure   Variables for the analyses 
    %   :pars:          structure   The Parameters for the timers
    %   :parent:        handle		Points to an object that controls this one
    %   :subs:          structure   Points to the objects which this one controls
    %   Output
    %   :self:          handle      A handle that points to the saveTimer object
        if nargin > 0
            wargs{1} = 'saver';
            wargs{2} = struct;
            if nargin > 6 
                wargs{3} = parent;
            end
            if nargin > 7 
                wargs{4} = subs;
            end
        else
            period = 0.5;
            hold = 30;
        end
        self@eventTimer(wargs{:});
        
        if nargin < 6
            pars.StartFcn = {@self.checkSaving};
            pars.TimerFcn = {@self.saveProcess};
            pars.ExecutionMode = 'fixedRate';
            pars.BusyMode = 'queue';
            pars.StartDelay = period;
            pars.Period = period;
            pars.TasksToExecute = inf;
        end
        buildTimers(self, self.name, pars)
        
        self.info_log = info_log;
        self.ECoG = ECoG;
        self.period = period;
        self.hold = hold;
        self.allow_save = true;
        self.skip = false;
        self.skipped = false;
        
        self.arguments = args;
    end
    
    function saveOut(self)
    % saveOut
    %   Saves the data and clears data structures to save memory
    %   Input
    %   :self:      handle      A handle that points to the saveTimer object
        % Set Up Variables to Save %
        args = get(self, 'arguments');
        ECoG = self.ECoG;
        info_log = self.inputs.info_log;
        
        all_timestamps.saver = self.timestamps;
        sub_names = fieldnames(self.subevents);
        for index = 1:length(sub_names)
            child = self.subevents.(sub_names{index});
            all_timestamps.(child.name) = child.timestamps;
        end
        
        % Save Variables %
        saveTrial(args.save_path, args.patient_ID, args.trial_name, ECoG, args, all_timestamps, info_log);
        append(info_log, 'Saving Complete', true, true);
        
        % Set data to retain and clear structures %
        endex = self.parent.timestamps.stamp_index;
        last = self.parent.timestamps.stamps.list(endex).e_adj_sn;
        blank_data = NaN(1,floor(args.sample_rate*(self.period+self.hold+10)));
        hold_samples = floor(self.hold*args.sample_rate);
        retainRecordingData(ECoG, hold_samples, last, blank_data);
        
%         output_types = fieldnames(ECoG.processed_signals);
%         for index = 1:length(output_types)
%             output_names = fieldnames(ECoG.processed_signals.(output_types{index}));
%             for j = 1:length(output_names)
%                 clearData(ECoG.processed_signals.(output_types{index}).(output_names{j}));
%             end
%         end
        
        % Adjust Times Stamps %
        new_adj = last - hold_samples;
        self.parent.timestamps.adjustment = new_adj;
        resetIndexing(self.parent.timestamps);
        
        for index = 1:length(sub_names)
            ts = self.subevents.(sub_names{index}).timestamps;
            ts.adjustment = new_adj;
            resetIndexing(ts);
        end
    end
    
    
    %% ---- Timer Functions ---- %%
    function checkSaving(obj, event, time, self)
    % ceckSaving
    %   The first function to be run by timers which checks if there will
    %   be any saving done
    %   Input
    %   :object:    handle      The timer object
    %   :event:     handle      An unused Matlab feature
    %   :time:      handle      An unused reference 
    %   :self:      handle      A handle that points to the saveTimer object
        info_log = self.info_log;
        if self.period >= self.timestamps.time_limit
            stopTimers(self, true);
        else
            append(info_log, sprintf('Saving in %d min.',floor(self.period/60)), true, true);
        end
    end

    function saveProcess(obj, event, time, self)
    % saveProcess
    %   The function that will periodicly save the data
    %   Input
    %   :object:    handle      The timer object
    %   :event:     handle      An unused Matlab feature
    %   :time:      handle      An unused reference 
    %   :self:      handle      A handle that points to the saveTimer object
        info_log = self.info_log;
        
        if self.allow_save && ~self.skip
            saveOut(self);
            self.skipped = false;
        else
            self.skip = false;
            self.skipped = true;
        end
        
        append(info_log, sprintf('Saving in %d min.',floor(self.period/60)), true, true);
        % ---- End this cycle ---- %
        if toc(self.timestamps.start_tic) >= self.timestamps.time_limit-self.period
            stopTimers(self, true);
            return
        end
    end
end
    
end