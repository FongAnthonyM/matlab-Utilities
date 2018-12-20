classdef analysisTimer < eventTimer
% analysisTimer 
%   An eventTimer subclass that runs a user defined analysis.
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
%   :period:        double                  The period of the analyses in [s]
%   :window:        double                  The window of the analyses in [s]
%   :window_sn:     double                  The window of the analyses in samples
%   :change:        boolean                 A trigger to change the analyses settings
%   :plot_args:     struct                  A struct of the plot parameters
%   :max_point:     matrix                  A matrix of the max point in the data
%   
%   :device:        object                  The device this analysis will be using

properties
    period
    window
    window_sn
    change
    
    max_points
    
    device
end

methods
    %% ---- Methods ---- %%
    function self = analysisTimer(name, device, period, window, args, vars, pars, parent, subs)
    % analysisTimer 
    %   Initializes the analysistimer object
    %   Input
    %   :name:          string      The name of this analysis object
    %   :device:        object      The device this analysis will be using
    %   :period:        double      The period of the analyses in [s]
    %   :window:        double      The window of the analyses in [s]
    %   :plot_args:     struct      A struct of the plot parameters
    %   :inputs:        struct      A struct of the input objects
    %   :args:          structure	Arguments for the analyses
    %   :vars:          structure   Variables for the analyses 
    %   :pars:          structure   The Parameters for the timers
    %   :parent:        handle		Points to an object that controls this one
    %   :subs:          structure   Points to the objects which this one controls
    %   Output
    %   :self:          handle      A handle that points to the analysisTimer object
        if nargin > 0
            wargs{1} = name;
            wargs{2} = struct;
            if nargin > 7
                wargs{3} = parent;
            end
            if nargin > 8 
                wargs{4} = subs;
            end
        else
            period = 10;
            window = 10;
            
            device = [];
        end
        self@eventTimer(wargs{:});
        
        if nargin < 5
            args = struct();
        end
        if nargin < 6
            vars = struct();
        end
        if nargin < 7
            pars.ExecutionMode = 'fixedRate';
            pars.BusyMode = 'queue';
            pars.StartDelay = window;
            pars.Period = period;
            pars.TasksToExecute = inf;
        end
        buildTimers(self, self.name, pars)
        
        self.period = period;
        self.window = window;
        self.window_sn = floor(window * device.sample_rate);
        self.device = device; 
        self.max_points(1:10) = 0.0000001;
        self.change = false;
        
        self.arguments = args;
        self.variables = vars;
    end
    
    function addPlotData(self, name, y, start, stop, start_tic, rs_factor, plot_before, plot_after)
    % addPlotData
    %   Adds data to the plot objects
    %   Input
    %   :self:          handle          A handle that points to the anaylsisTimer object
    %   :y:             cell array      The data to add to the plots
    %   :start:         double          The period of the analyses in [s]
    %   :stop:          double          The window of the analyses in [s]
    %   :start_tic:     double          The tic which is the start of the trial
    %   :rs_factor:     double          The resample factor
    %   :plot_before:   double          The view distance of the plot before the current time
    %   :plot_after:    double          The view distance of the plot after the current time 
        current_time = toc(start_tic);

        for plot = 1:length(self.plots.(name).plots)
            parent = self.plots.(name).plots(plot);
            
            y{plot}(length(y{plot})) = NaN;                                     % Add a NaN at the end to prevent a line being drawn from endpoint to endpoint
            if rs_factor == 1
                y_ch = y{plot};
            else
                y_ch = resample(y{plot}, 1, rs_factor);
            end
            x_ds = linspace(start, stop, length(y_ch));
            addpoints(parent.animeline,x_ds,y_ch)
            
            set(parent.b_analysis_line, 'XData', [start start]);
            set(parent.e_analysis_line, 'XData', [stop stop]);
            set(parent.delay_line, 'XData', [stop current_time]);
            xlim(parent.subplot, [current_time - plot_before current_time + plot_after])
            % Adjust the Y limit if needed
            maxi = max(abs(y_ch));
            if maxi > self.max_points(plot)
                self.max_points(plot) = maxi;
                ylim(parent.subplot, ([-maxi maxi]*1.1));
            end
        end
    end

    
    
end
    
end