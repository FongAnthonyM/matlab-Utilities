classdef Variance < matlab.System

    % Public, non-tunable properties
    properties(Nontunable)
        W    = 0;
        Dim  = 'all';
        
        VariancePlotPresent = false;
        VarianceMap         = [];
        VariancePlot
        AveragePlotPresent  = false;
        AverageMap
        AveragePlot
    end
    

    methods
        % Constructor
        function obj = Variance(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
        
        function plt = buildVaPlot(obj, names, map, override)
            if ischar(names)
                names = {names};
            end
            if nargin < 4
                override = false;
            end
            
            if override || isempty(obj.CoherencePlot)
                plt = realmultiplot([600 length(names)*150], names, 'Name', 'Variance', 'Visible', 'off');
                plt.lineplots();
                plt.setLabels('all', 'Time [s]', 'Voltage [V]');
                plt.setLimits('all', [0 1], [0 1]);
                plt.pointText(true);
                obj.VariancePlot = plt;
                obj.VarianceMap = map;
            else
                plt = obj.VariancePlot;
            end
            obj.VariancePlotPresent = true;
        end
        
        function plt = buildAvPlot(obj, names, map, override)
            if ischar(names)
                names = {names};
            end
            if nargin < 4
                override = false;
            end
            
            if override || isempty(obj.AveragePlot)
                plt = realmultiplot([600 length(names)*300], names, 'Name', 'Variance', 'Visible', 'off');
                plt.lineplots();
                plt.setLabels('all', 'Time [s]', 'Variance');
                plt.setLimits('all', [0 1]);
                plt.pointText(true);
                obj.AveragePlot = plt;
                obj.AverageMap = map;
            else
                plt = obj.AveragePlot;
            end
            obj.AveragePlotPresent = true;
        end
        
        function plotTracking(obj, t)
            if obj.VariancePlotPresent
                obj.VariancePlot.Track = t;
            end
            if obj.AveragePlotPresent
                obj.AveragePlot.Track = t;
            end
        end
    end

    methods(Access = protected)
        %% Common functions

        function [var, a_var] = stepImpl(obj, x, time)
            c_map = obj.VarianceMap;
            a_map = obj.AverageMap;
            dim   = obj.Dim;
            
            var = nanvar(x, obj.W, dim);
            a_var = var;
            for i = 1:dim-1
                a_var = nanmean(a_var);
            end
            
            if obj.VariancePlotPresent
                % Reshaped Adjusted Variance [Y, X] to vector X*[Y]
                % [Y,X] Map is made with reshape(1:(Y*X),[Y,X]) 
                obj.VariancePlot(reshape(var,[1,numel(adj_c)]), time, c_map);
            end
            
            if obj.AveragePlotPresent
                obj.AveragePlot(a_var, time, a_map);
            end
        end
    end
end
