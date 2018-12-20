classdef trialScheduler < matlab.mixin.SetGet

    
properties
    info_log
    device
    duration
    
    timers
end

methods
    function self = trialScheduler(device, info_log, trial, saver, recorder)
        self.timers.trial       = struct();
        self.timers.saver       = struct();
        self.timers.record      = struct();
        self.timers.analyses    = struct();
        self.timers.stimulators = struct();
        
        if nargin > 0
            self.info_log = info_log;
            self.device = device;
            if nargin > 2
                self.timers.trial = trial;
                self.duration = trial.duration;
                if nargin > 3
                    self.timers.saver = saver;
                    if nargin > 4
                        self.timers.recorder = recorder;
                        recorder.addSubevents({saver});
                        trial.addSubevents({recorder, saver});
                    end
                end
            end
        end
    end
    
    function addTimer(self, et)
        self.timers.(et.name) = et;
    end
    
    function addAnalyses(self, a)
        if iscell(a)
            for i = 1:length(a)
                a{i}.timestamps.time_limit = self.duration;
                self.timers.analyses.(a{i}.name) = a{i};
            end
        else
            a.timestamps.time_limit = self.duration;
            self.timers.analyses.(a.name) = a;
        end
        addSubevents(self.timers.trial, a);
        addSubevents(self.timers.saver, a);
        addSubevents(self.timers.recorder, a);
    end
    
    function addStimulators(self, a)
        if iscell(a)
            for i = 1:length(a)
                a{i}.timestamps.time_limit = self.duration;
                self.timers.stimulators.(a{i}.name) = a{i};
            end
        else
            a.timestamps.time_limit = self.duration;
            self.timers.stimulators.(a.name) = a;
        end
        addSubevents(self.timers.trial, a);
        addSubevents(self.timers.saver, a);
        addSubevents(self.timers.recorder, a);
    end    
end
    
end

