classdef CAR < matlab.System
    
    properties
        Allow = true;
    end

    % Public, non-tunable properties
    properties(Nontunable)
        Pairs         = {};
        nPairs        = 0;
        IncludeTarget = true;
        mChan         = 2;
        
        PlotPresent   = false;
        ChannelMap    = [];
        Plot
    end

    % Pre-computed constants
    properties(Access = private)
        Possible
    end

    methods
        % Constructor
        function obj = CAR(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
            obj.nPairs = length(obj.Pairs);
        end
        
        function plt = buildPlot(obj, names, map, override)
            if ischar(names)
                names = {names};
            end
            if nargin < 4
                override = false;
            end
            
            if override || isempty(obj.Plot)
                plt = realmultiplot([600 length(names)*150], names, 'Name', 'CAR', 'Visible', 'off');
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
    end

    methods(Access = protected)
        %% Common functions
        function setupImpl(obj)
            pairs  = obj.Pairs;
            m_chan = obj.mChan;
            for p = 1:obj.nPairs
                tg = length(pairs{p,1});
                rf = length(pairs{p,2});
                obj.Possible(p) = tg+rf > m_chan;
            end
        end

        function y = stepImpl(obj, u, time)
            pairs   = obj.Pairs;
            include = obj.IncludeTarget;
            map     = obj.ChannelMap;
            y = [];
            
            if obj.Allow
                for p = 1:obj.nPairs
                    targets = u(:, pairs{p,1});
                    if obj.Possible(p)
                        references = u(:, pairs{p,2});
                        y = [y, car(targets, references, include)];
                    else
                        y = [y, targets];
                    end
                end
            end
            if obj.PlotPresent
                obj.Plot(y, time, map)
            end
        end

        function resetImpl(obj)
            pairs  = obj.Pairs;
            m_chan = obj.mChan;
            for p = 1:obj.nPairs
                tg = length(pairs{p,1});
                rf = length(pairs{p,2});
                obj.Possible(p) = tg+rf > m_chan;
            end
        end
    end
end
