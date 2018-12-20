classdef recordTimer < eventTimer
% recordTimer 
%   An eventTimer subclass that records data from a specified daq.
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
%   :period:        double                  The period of the record Timer in [s]
%   :plot_args:     struct                  A struct of the plot parameters
%   :max_point:     matrix                  A matrix of the max point in the data
%   
%   :daq:        object                     The daq this analysis will be using

properties
    info_log
    daq
    process
    
    r_data
    p_data
    n_data
    c_data
    
    period
end

methods
    %% ---- Methods ---- %%
    function self = recordTimer(info_log, period, daq, r_data, process, pars, parent, subs)
    % recordTimer 
    %   Initializes the recordTimer object
    %   Input
    %   :daq:           object      The object to get the data from
    %   :period:        double      The period of data collection in seconds
    %   :inputs:        struct      A struct of the input objects
    %   :args:          structure	Arguments for the analyses
    %   :pars:          structure   The Parameters for the timers
    %   :parent:        handle		Points to an object that controls this one
    %   :subs:          structure   Points to the objects which this one controls
    %   Output
    %   :self:          handle      A handle that points to the recordTimer object
        if nargin > 0
            wargs{1} = 'record_data';
            wargs{2} = struct;
            if nargin > 6 
                wargs{3} = parent;
            end
            if nargin > 7
                wargs{4} = subs;
            end
        else
            period = 0.5;
        end
        self@eventTimer(wargs{:});
        
        if nargin < 6
            pars.TimerFcn       = {@self.recordData};
            pars.StopFcn        = {@self.stopRecord};
            pars.ExecutionMode  = 'fixedRate';
            pars.BusyMode       = 'drop';
            pars.StartDelay     = period;
            pars.Period         = period;
            pars.TasksToExecute = inf;
        end
        buildTimers(self, self.name, pars)    
        
        self.daq      = daq;
        self.info_log = info_log;
        self.period   = period;
        self.r_data   = r_data;
        
        if nargin >= 5
            self.process = process;
        end
    end
    
    function initRecordData(self)
    % initRecordData
    %   Initializes the data collection
    %   Input
    %   :self:      handle      A handle that points to the recordTimer object
        self.daq.initDAQ();
    end
    
    function plotTracking(self, t)
        self.process.plotTracking(t);
    end
    
    function [raw, ts] = collectData(self)
    % collectData
    %   Gets the data from the daq, puts it in a data structure
    %   Input
    %   :self:          handle          A handle that points to the recordTimer object
    %   Outputs
    %   :raw_data:              cell array      The new data since the last call to collectData
    %   :sample_rate:           double          The number of samples persecond
    %   :samples_perchannel:    double          The number of samples per channel
    %   :last_sample:           double          The absolute sample number of the last sample in the new data
    %   :new_ts:                double          The new timestamp
        [raw, ts] = self.daq(self.timestamps);
        
        f_sn = ts.b_adj_sn;
        l_sn = ts.e_adj_sn;
        f_sc = ts.b_seconds;
        l_sc = ts.e_seconds;
        
        % Add data to struct
        [sam, cha] = size(raw);
        self.r_data.addDataList(mat2cell(raw,ones(1,sam),cha), f_sn:l_sn);
        
        % Extra Processing
        if ~isempty(self.process)
            [c, n, re] = self.process(raw.', [f_sc l_sc]);
            [sam, cha] = size(n);
            tch = size(c,2);
            if ~isempty(self.p_data) && ~isempty(re)
                self.p_data.appendDataNaNList(mat2cell(re,sam,ones(1,cha)),1);
            end
            if ~isempty(self.n_data) && ~isempty(n)
                self.n_data.appendDataNaNList(mat2cell(n,sam,ones(1,cha)),1);
            end
            if ~isempty(self.c_data) && ~isempty(c)
                self.c_data.appendDataNaNList(mat2cell(c,sam,ones(1,tch)),1);
            end
        end
    end
    
    %% ---- Timer Functions ---- %%
    function recordData(~, ~, ~, self)
    % recordData
    %   The function that will periodicly record the data from the daq
    %   Input
    %   :object:    handle      The timer object
    %   :event:     handle      An unused Matlab feature
    %   :time:      handle      An unused reference 
    %   :self:      handle      A handle that points to the recordTimer object
        % ---- Data Collection Cycle ---- %
        collectData(self);

        % ---- End this cycle ---- %
        if toc(self.timestamps.start_tic) >= self.timestamps.time_limit
            stopTimers(self, true);
        end
    end
    
    function stopRecord(~, ~, ~, self)
        self.daq.shutdown();
    end
end
    
end