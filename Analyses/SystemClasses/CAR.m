classdef CAR < matlab.System
    
    properties
        Allow = true;
    end

    % Public, non-tunable properties
    properties(Nontunable)
        Pairs             = [];
        nPairs            = 0;
        IncludeTarget     = true;
        mChan             = 2;
        
        DataStructPresent = false; 
        DataStruct
        
        PlotPresent       = false;
        ChannelMap        = [];
        Plot
    end

    % Pre-computed constants
    properties(Access = private)
        Possible
    end
    
    methods(Static)
        function pairs = pairstruct(tg_names, rf_names, tg_list, rf_list)
            pairs = struct;
            for r = 1:length(tg_names)
                pairs(r).target.name = tg_names{r};
                pairs(r).reference.name = rf_names{r};
                pairs(r).target.channels = tg_list{r};
                pairs(r).reference.channels = rf_list{r};
            end
        end
    end

    methods
        % Constructor
        function obj = CAR(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
            obj.nPairs = length(obj.Pairs);
            if ~isempty(obj.DataStruct)
                obj.DataStructPresent = true;
            end
        end
        
        function [y, ds] = car(obj, u, pairs)
            include = obj.IncludeTarget;
            y  = [];
            ds = struct();
            
            for p = 1:obj.nPairs
                type    = pairs(p).target.name;
                targets = u(:, pairs(p).target.channels);
                if obj.Possible(p)
                    references = u(:, pairs(p).reference.channels);
                    targets = car(targets, references, include);
                end
                [sam, cha] = size(targets);
                ds.(type) = mat2cell(targets,sam,ones(1,cha));
                y = [y, targets];
            end
        end
        
        function pairs = setPairstruct(obj, tg_names, rf_names, tg_list, rf_list)
            pairs = struct;
            for r = 1:length(tg_names)
                pairs(r).target.name = tg_names{r};
                pairs(r).reference.name = rf_names{r};
                pairs(r).target.channels = tg_list{r};
                pairs(r).reference.channels = rf_list{r};
            end
            obj.Pairs = pairs;
        end
        
        function setDataStruct(obj, ds)
            obj.DataStruct = ds;
            if ~isempty(ds)
                obj.DataStructPresent = true;
            else
                obj.DataStructPresent = false;
            end
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
            pairs = obj.Pairs;
            map   = obj.ChannelMap;
            y = [];
            
            if obj.Allow
                [y, ds] = obj.car(u, pairs);
                if obj.DataStructPresent
                    self.DataStruct.appendDataNaNType(ds, 1);
                end
                if obj.PlotPresent
                    obj.Plot(y, time, map)
                end
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
