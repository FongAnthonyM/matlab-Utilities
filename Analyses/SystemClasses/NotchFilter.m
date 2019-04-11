classdef NotchFilter < matlab.System
% NotchFilter

    properties
        Harmonics = 1;
    end
    
    % Public, non-tunable properties
    properties(Nontunable)
        SampleRate      = 512;
        Bandwidth       = 4;
        CenterFrequency = 60;
        Cascade         = 'manual';
        
        DataStructPresent = false; 
        DataStruct
        
        PlotPresent     = false;
        ChannelMap      = [];
        Plot
    end
    
    % Pre-computed constants
    properties(Access = private)
        nHarmonics = 1;
        Filters
    end
    
    properties(Constant, Hidden)
        CascadeSet = matlab.system.StringSet({'manual', 'auto'});
    end

    methods
        % Constructor
        function obj = NotchFilter(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
            if ~isempty(obj.DataStruct)
                obj.DataStructPresent = true;
            end
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
                plt = realmultiplot([600 length(names)*150], names, 'Name', 'Notch', 'Visible', 'off');
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
        
        function harm = getHarmonics(obj)
        % getHarmonics
            if strcmpi(obj.Cascade,'auto')
                harm = floor(obj.SampleRate/(obj.CenterFrequency * 2));
                obj.Harmonics = harm;
            elseif strcmpi(obj.Cascade,'manual')
                harm = obj.Harmonics;
            end
            obj.nHarmonics = harm;
        end
    end

    methods(Access = protected)
        %% ---- Implementation Functions ---- %%
        function setupImpl(obj)
        % setupImpl    
            obj.buildFilters();
        end

        function u = stepImpl(obj, u, time)
        % stepImpl
            n_harm = obj.nHarmonics;
            filts  = obj.Filters;
            map    = obj.ChannelMap;
            for index = 1:n_harm
                u = filts{index}(u);
            end
            if obj.DataStructPresent
                [sam, cha] = size(u);
                obj.DataStruct.appendDataNaNList(mat2cell(u,sam,ones(1,cha)),1);
            end
            if obj.PlotPresent
                obj.Plot(u, time, map);
            end
        end

        function resetImpl(obj)
        % resetImpl
            obj.buildFilters();
        end
        
        %% ---- Helper Functions ---- %%
        function buildFilters(obj)
        % buildFilters
            harm        = obj.getHarmonics();
            center      = obj.CenterFrequency;
            band        = obj.Bandwidth;
            obj.Filters = cell(harm,1);
            
            for i = 1:harm
                obj.Filters{i} = dsp.NotchPeakFilter('SampleRate',512,...
                                                     'CenterFrequency', center*i,...
                                                     'Bandwidth',band);
            end
        end
    end
end
