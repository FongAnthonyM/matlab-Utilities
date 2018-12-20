classdef DAQ < matlab.System
    
    properties
        Name = 'Raw'
    end

    % Public, non-tunable properties
    properties(Nontunable)
        Device
        IDs
        
        PlotPresent   = false;
        ChannelMap    = [];
        Plot
    end

    methods
        % Constructor
        function obj = DAQ(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
        
        function plt = buildPlot(obj, names, map, override)
            if nargin < 4
                override = false;
            end
            
            if override || isempty(obj.Plot)
                plt = realmultiplot([600 length(names)*150], names, 'Name', obj.Name, 'Visible', 'off');
                plt.setLabels('all', 'Time [s]', 'Voltage [V]');
                plt.setLimits('all', [0 1]);
                obj.Plot = plt;
                obj.ChannelMap = map;
            else
                plt = obj.Plot;
            end
            obj.PlotPresent = true;
        end
        
        function plotTracking(obj, t)
            if obj.PlotPresent
                obj.Plot.Track = t;
            end
        end
        
        function initDAQ(obj)
        % initDAQ
        %   Initializes the data collection
        %   Input
        %   :obj:      handle      A handle that points to the recordTimer object
            obj.Device.initDataCollection();
        end
        
        function shutdown(obj)
            obj.Device.shutdown();
        end
    end

    methods(Access = protected)
        %% Common functions
%         function setupImpl(obj)
%             
%         end

        function [y, ts] = stepImpl(obj, timestamps)
            map = obj.ChannelMap;
            y = [];

            try
                [r_array, ts] = obj.Device.getData(obj.IDs, timestamps);
                timestamps.addTimestamp(ts);
            catch ME
                intro = 'Skipping a record data due to an error but still running. Error:';
                message = ME.message;
                fprintf('%s\n%s\n', intro, message);
                return
            end
            
            y = cell2mat(r_array.');
            
            if obj.PlotPresent
                obj.Plot(r_array.', start, stop, map)
            end
        end

        function resetImpl(obj)
            
        end
    end
end
