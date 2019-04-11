classdef DAQ < matlab.System
    
    properties
        Name = 'Raw'
    end

    % Public, non-tunable properties
    properties(Nontunable)
        Device
        IDs
        
        DataStructPresent = false; 
        DataStruct
        
        PlotPresent   = false;
        ChannelMap    = [];
        Plot
    end

    methods
        % Constructor
        function obj = DAQ(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
            if ~isempty(obj.DataStruct)
                obj.DataStructPresent = true;
            end
        end
        
        function plt = buildPlot(obj, names, map, override)
            if nargin < 4
                override = false;
            end
            
            if override || isempty(obj.Plot)
                plt = realmultiplot([600 length(names)*150], names, 'Name', obj.Name, 'Visible', 'off');
                plt.lineplots();
                plt.setLabels('all', 'Time [s]', 'Voltage [V]');
                plt.setLimits('all', [0 1]);
                obj.Plot = plt;
                obj.ChannelMap = map;
            else
                plt = obj.Plot;
            end
            obj.PlotPresent = true;
        end
        
        function setDataStruct(obj, ds)
            obj.DataStruct = ds;
            if ~isempty(ds)
                obj.DataStructPresent = true;
            else
                obj.DataStructPresent = false;
            end
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
            
            y = cell2mat(r_array.').';
            
            if obj.DataStructPresent
                f_sn = ts.b_adj_sn;
                l_sn = ts.e_adj_sn;
                obj.DataStruct.addDataList(r_array,f_sn:l_sn);
            end
            
            if obj.PlotPresent
                obj.Plot(r_array.', start, stop, map);
            end
        end
    end
end
