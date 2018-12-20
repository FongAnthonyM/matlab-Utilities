classdef timestampsStruct < matlab.mixin.SetGet
% timestampsStruct
%   A handles (Set & Get type) subclass that contains timing information
%   :self:          handle		A handle that points to the timestamps object
%   :name:			string		Name of the timestamps object
%   :beginning:		datetime	The datetime of the beginning of the trial	
%   :zero:			double		The relative sample number that the trial starts on
%   :adjustment:	double		The relative sample number that this save file segment is based on
%   :time_limit:	double		The assigned time in seconds that this trial was supposed to last
%   :start_tic:		tic			A tic created at the beginning of the trial for timing
%   :stamp_number:	double		The absolute number of stamps
%   :stamp_index:	double		The relative number of stamps that this save file segment has
%   :stamps:		structure	List of stamps and all of their information

properties
    self
    name
    
    beginning
    zero = 0
    adjustment = 0
    time_limit
    start_tic
    stamp_number = 0
    stamp_index = 0

    stamps
end

methods
    %% ---- Methods ---- %%
    function self = timestampsStruct(name)
    % timestampsStruct
    %   Creates and builds a timestampsStruct object
    %   Inputs
    %   :name:		string		The name of the timestamp object
    %   Outputs
    %   :self:		handle      A handle that points to the timestamp object
        if nargin == 1
            self.self = self;
            self.name = name;
        end
    end
    
    function [current_timeindex] = addTimestamp(self, info)
    % addTimestamp
    %   Adds a new time stamp to the stamps structure and edits indexing approriately 
    %   Inputs
    %   :self:		handle      A handle that points to the timestamp object
    %   :info:		struct		The structure of the new timestamp
    %   Outputs
    %   :current_timeindex:     double  The index of new timestamp
        self.stamp_number = self.stamp_number + 1;
        info.number = self.stamp_number;
        current_timeindex = self.stamp_index + 1;
        self.stamp_index = current_timeindex;
        
        self.stamps.list(current_timeindex) = info;
    end
    
    function resetIndexing(self)
    % resetIndexing
    %   Resets indexing but sets the last timestamp to the new first timestamp 
    %   Inputs
    %   :self:		handle      A handle that points to the timestamp object
        if self.stamp_index
            temp_stamp = self.stamps.list(self.stamp_index);
            self.stamps = [];
            self.stamps.list(1) = temp_stamp;
            self.stamp_index = 1;
        end
    end
    
    function resetTimestamps(self)
    % resetTimestamps
    %   Resets timestamps but sets the last timestamp to the new first timestamp 
    %   Inputs
    %   :self:		handle      A handle that points to the timestamp object
        resetIndexing(self)
        self.stamp_number = 1;
    end
    
    function [ts] = returnStamp(self, index)
    % returnStamp
    %   Returns the timestamp at the given index in this timestampStruct object
    %   Inputs
    %   :self:		handle      A handle that points to the timestamp object
    %   :index:     double      The index of the timestamp to return
    %   Output
    %   :ts:        struct      The timestamp to return
        ts = self.stamps.list(index);
    end
    
    function [last] = returnLastStamp(self)
    % returnLastStamp
    %   Returns the last timestamps in this timestampStruct object
    %   Inputs
    %   :self:		handle      A handle that points to the timestamp object
    %   Output
    %   :last:      struct      The timestamp to return
        last = self.stamps.list(self.stamp_index);
    end
    
    function setLastStamp(self, ts)
    % setLastStamp
    %   Returns the last timestamps in this timestampStruct object
    %   Inputs
    %   :self:		handle      A handle that points to the timestamp object
        self.stamps.list(self.stamp_index) = ts;
    end
end
    
end

