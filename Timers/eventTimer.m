classdef eventTimer < matlab.mixin.SetGet
% eventTimer 
%   A handles (Set & Get type) subclass that effeciently controls timers.
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
    
properties
    % Object
    self
    parent
    subevents = struct
    name
    timer_args
    
    % Data
    arguments
    variables
    timestamps
    inputs
    outputs
    fig
    plots
    
    % Timing
    auto_start = true
    interruptable = true
    inherent_delay = 0
    current_timer = 2
    timers
end
    

methods
    %% ---- Methods ---- %%
    function self = eventTimer(name, args, parent, subs)
    % eventTimer 
    %   Creates and builds an eventTimer object
    %   Input
    %   :name:      string		Name of the event timer
    %   :args:      structure	Arguments for the timers
    %   :parent:    handle		Points to an object that controls this one
    %   :subs:      structure   Points to the objects which this one controls
    %   Output
    %   :self:      handle      A handle that points to the eventTimer object
        if nargin > 0
            self.name = name;
            self.self = self;
            self.timestamps = timestampsStruct(name);
            if nargin >= 2
                self.timer_args = args;
                buildTimers(self, name, args)
            end
            if nargin >= 3
                self.parent = parent;
            end    
            if nargin >= 4
                subevents = struct;
                for sub = 1:length(subs)
                    child = subs{sub};
                    subevents.(child.name) = child;
                    set(child, 'parent', self)
                end
                self.subevents = subevents;
            end
        end
    end
    
    function build(self, name, args, parent, subs)
    % build
    %   Set the initial properties and creates the timers
    %   Input
    %   :self:      handle              A handle that points to the eventTimer object
    %   :name:      string              The name of this object. This should be the same as the variable name.
    %   :args:      structure           Contains all the variables for the timer.
    %   :parent:    handle              Points to an object that controls this one.
    %   :subs:      array of handles    Points to the objects which this one controls.
        % Assign the Properties
        self.name = name;
        self.self = self;
        self.timestamps = timestampsStruct(name);
        if nargin >= 3
            self.timer_args = args;
            buildTimers(self, name, args)
        end
        if nargin >= 4
            self.parent = parent;
        end    
        if nargin >= 5
            subevents = struct;
            for sub = 1:length(subs)
                child = subs{sub};
                subevents.(child.name) = child;
                set(child, 'parent', self)
            end
            self.subevents = subevents;
        end
    end

    function buildTimers(self, name, args)
    % buildTimers
    %   Creates the timers
    %   Input
    %   :self:      handle              A handle that points to the eventTimer object
    %   :name:      string              The name of this object. This should be the same as the variable name.
    %   :args:      structure           Contains all the variables for the timer.
        % Add the self handle of this object to timer arguments 
        self.timer_args = args;
        funcs = {'TimerFcn','ErrorFcn','StartFcn','StopFcn'};
        fields = fieldnames(args);
        
        for i = 1:length(fields)
            for j = 1:length(funcs)
                if strcmp(fields(i), funcs(j))
                    args.(fields{i}){length(args.(fields{i}))+1} = self;
                end
            end
            if strcmp(fields(i), 'StartDelay')
                self.inherent_delay = args.StartDelay;
            end
        end
        
        % Build Timers
        for t = 1:2
            timers(t) = timer;
            timers(t).Name = sprintf('%s%d',name,t);
            % Use args structure to define timers
            for index = 1:length(fields)
                timers(t).(fields{index}) = args.(fields{index});
            end
        end
        self.timers = timers;
    end
    
    function setSubevents(self, subs)
    % setSubevents
    %   Set the subevents for this eventTimer
    %   Input
    %   :self:      handle              A handle that points to the eventTimer object
    %   :subs:      array of handles    Points to the objects which this one controls
        subevents = struct;
        if isa(subs,'cell')
            for sub = 1:length(subs)
                child = subs{sub};
                subevents.(child.name) = child;
                set(child, 'parent', self)
            end
        else
            subevents.(subs.name) = subs;
            set(subs, 'parent', self)
        end
        self.subevents = subevents;
    end
    
    function addSubevents(self, subs)
    % addSubevents
    %   Adds the subevents for this eventTimer
    %   Input
    %   :self:      handle              A handle that points to the eventTimer object
    %   :subs:      array of handles    Points to the objects which this one controls
        if isa(subs,'cell')
            for sub = 1:length(subs)
                child = subs{sub};
                self.subevents.(child.name) = child;
                set(child, 'parent', self)
            end
        else
            self.subevents.(subs.name) = subs;
            set(subs, 'parent', self)
        end
    end
    
    function startSubevents(self, allow)
    % startSubevents
    %   Starts the subevents of this eventTimer
    %   Input
    %   :self:      handle      A handle that points to the eventTimer object
    %   :allow:     boolean  	Display that the timer started     
        sub_names = fieldnames(self.subevents);
        for index = 1:length(sub_names)
            if self.subevents.(sub_names{index}).auto_start
                startNextTimer(self.subevents.(sub_names{index}), allow);
            end
        end
    end
    
    function stopSubevents(self, allow)
    % stopSubevents
    %   Stops the subevents of this eventTimer
    %   Input
    %   :self:      handle      A handle that points to the eventTimer object
    %   :allow:     boolean  	Display that the timer stoped
        sub_names = fieldnames(self.subevents);
        for index = 1:length(sub_names)
            if self.subevents.(sub_names{index}).interruptable
                stopTimers(self.subevents.(sub_names{index}), allow);
            end
        end
    end
    
    function begin(self, list, allow)
    % begin
    %   Starts a set of timers based on a list of indices
    %   Input
    %   :self:      handle    A handle that points to the eventTimer object
    %   :list:      matrix    List of indices to start
        for index = 1:length(list)
            if allow
                fprintf('%s timer %d has started\n', self.name, index);
            end
            start(self.timers(list(index)));
        end
    end
    
    function setNextTimer(self, args)
    % setNextTimer
    %   Sets the arguments for the next timer
    %   Input
    %   :self:      handle              A handle that points to the eventTimer object
    %   :args:      structure           Contains all the variables for the next timer.
        next_timer = nextTimer(self);
        fields = fieldnames(args);
        % Use args structure to define timer
        for index = 1:length(fields)
            set(self.timers(next_timer), (fields{index}), args.(fields{index}));
        end
    end
    
    function startNextTimer(self, allow)
    % startNextTimer
    %   Starts the next timer in the timer list
    %   Input
    %   :self:      handle    A handle that points to the eventTimer object
        next_timer = nextTimer(self);
        begin(self, next_timer, allow);
        self.current_timer = next_timer;
    end
    
    function stopTimers(self, allow)
    % stopTimer
    %   Stops the all the timers
    %   Input
    %   :self:      handle    A handle that points to the eventTimer object
    %   :allow:     boolean   Display that the timer stopped
        stop(self.timers);
        if allow
            fprintf('%s timers have stopped\n', self.name);
        end
    end

    function setInputs(self, names, data)
    % setInputs
    %   Sets the inputs for the eventTimer
    %   Input
    %   :self:      handle                  A handle that points to the eventTimer object
    %   :names:     handle/cell array       Either object to set as the input or array names for making blank data
    %   :data:      matrix                  Default data to use if making blank data
        if isstruct(names) || isa(names, 'handle')
            inputs = names;
        elseif isa(names, 'cell')
            total = length(names);
            for index = 1:total
                inputs.(names{index}).data = data{index}; 
            end
        else
            inputs.(names).data = data;
        end
        self.inputs = inputs;
    end
    
    function addInputs(self, names, data) 
    % addInputs
    %   Adds an input to the eventTimer
    %   Input
    %   :self:      handle                  A handle that points to the eventTimer object
    %   :names:     cell array              The names of the data adding
    %   :data:      handles/matrix          Either object to set as the input or default data to use if making blank data
        if isa(names, 'cell')
            total = length(names);
            for index = 1:total
                self.inputs.(names{index}).data = data{index}; 
            end
        elseif isstruct(data) || isa(data, 'handle')
            self.inputs.(names) = data;
        else
            self.inputs.(names).data = data;
        end
    end
    
    function setOutputs(self, names, data)
    % setOutput
    %   Sets the output for the eventTimer
    %   Input
    %   :self:      handle                  A handle that points to the eventTimer object
    %   :names:     handle/cell array       Either object to set as the input or array names for making blank data
    %   :data:      matrix                  Default data to use if making blank data
        if isstruct(names) || isa(names,'handle')
            outputs = names;
        elseif isa(names, 'cell')
            total = length(names);
            for index = 1:total
                if isa(data, 'cell')
                    outputs.(names{index}) = signalstruct(names{index}, index, {'none',1}, data{index});
                else
                    outputs.(names{index}) = signalstruct(names{index}, index, {'none',1}, data);
                end
            end
        else
            outputs.(names) = signalstruct(names, 1, {'none',1}, data);
        end
        self.outputs = outputs;
    end

    function addOutputs(self, names, data)
    % addOutputs
    %   Adds outputs to the eventTimer
    %   Input
    %   :self:      handle                  A handle that points to the eventTimer object
    %   :names:     cell array              The names of the data adding
    %   :data:      handles/matrix          Either object to set as the input or default data to use if making blank data
        if isa(names, 'cell')
            total = length(names);
            for index = 1:total
                if isa(data, 'cell')
                    self.outputs.(names{index}) = signalstruct(names{index}, index, {'none',1}, data{index});
                else
                    self.outputs.(names{index}) = signalstruct(names{index}, index, {'none',1}, data);
                end 
            end
        elseif isstruct(data)  || isa(data, 'handle')
            self.outputs.(names) = data;
        else
            self.outputs.(names) = signalstruct(names, 1, {'none',1}, data);
        end
    end
    
    function out = createPlots(self, name, varargin)
    % createPlots
    %   Creates plots for the eventTime
    %   Input
    %   :self:      handle                  A handle that points to the eventTimer object
    %   :list:      structure/cell array    An array of plot names whose shape will determine the subplot settings
    %   :parent:    handle/string           Either the handle to figure to place the plots
    %                                       or the name for the new figure
    %   :vis:       boolean                 Choose the visiblity of the figure    
        out = scrollmultiplot(varargin{:});
        self.plots.(name) = out;
    end
    
    
    function next_timer = nextTimer(self)
    % nextTimer
    %   The index of the next timer that would run on startNextTimer
    %   Inputs
    %   :self:      handle  A handle that points to the eventTimer object
    %   Outputs
    %   :next_timer:    double  The index of the next timer
        if self.current_timer == length(self.timers)
            next_timer = 1;
        else
            next_timer = self.current_timer + 1;
        end
    end
end
    
end

