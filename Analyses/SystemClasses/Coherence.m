classdef Coherence < matlab.System

    % Public, non-tunable properties
    properties(Nontunable)
        Name = 'Coherence'
        Multiprocessing = false;
        
        Window
        Noverlap
        NFFT
        W
        MIMO
        F
        SampleRate
        Freqrange     
        
        PlotPresent   = false;
        ChannelMap    = [];
        Plot
    end
    
    properties(Access = private)
        CoFunction
        Varargin
        Ppool
    end

    methods
        % Constructor
        function obj = Coherence(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
            obj.setMultiprocessing();
            obj.parseParam();
        end
        
        function varargin = parseParam(obj)
            if ~isempty(obj.Window) 
                varargin{1} = obj.Window;
                if ~isempty(obj.Noverlap)
                    varargin{2} = obj.Noverlap;
                    if ~isempty(obj.NFFT)
                        varargin{3} = obj.NFFT;
                    elseif ~isempty(obj.W)
                        varargin{3} = obj.W;
                    elseif ~isempty(obj.F)
                        varargin{3} = obj.F;
                    end
                end
                if ~isempty(obj.MIMO)
                    varargin{end+1} = obj.MIMO;
                end
                if ~isempty(obj.SampleRate)
                    varargin{end+1} = obj.SampleRate;
                end
                if ~isempty(obj.Freqrange)
                    varargin{end+1} = obj.Freqrange;
                end
                obj.Varargin = varargin;
            end
        end
        
        function setMultiprocessing(obj)
            if obj.Multiprocessing
                obj.CoFunction = @obj.parmcohere;
                if isempty(gcp('nocreate'))
                    obj.Ppool = parpool('local',4);
                end
            else
                obj.CoFunction = @obj.multicohere;
            end
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
    end

    methods(Access = protected)
        %% Common functions
        function setupImpl(obj)
            obj.parseParam();
            obj.setMultiprocessing();
        end

        function varargout = stepImpl(obj, x, y, time)
            map = obj.ChannelMap;

            % Coherence (Sample, X, Y) or (Y, X, Frequency)
            [varargout{1:nargout}] = obj.CoFunction(x, y);
            
            if obj.PlotPresent
                if iscell(varargout)
                    varargout = varargout{1};
                end
                obj.Plot(varargout, time, map)
            end
        end
        
        function num = getNumOutputsImpl(~)
            num = 2;
        end
        
        function varargout = multicohere(obj, x, y)
            varargin = obj.Varargin;
            for i = 1:size(x, 2)
                [c_xy(:,i,:), f(:,i)] = mscohere(x(:,i), y, varargin{:});
            end
            varargout = {c_xy, f(:,1)};
        end
        
        function varargout = parmcohere(obj, x, y)
            [s, c] = size(x);
            varargin = obj.Varargin;
            parfor i = 1:c
                [c_xy(:,i,:), f(:,i)] = mscohere(x(:,i), y, varargin{:});
            end
            varargout = {c_xy, f(:,1)};
        end
    end
end
