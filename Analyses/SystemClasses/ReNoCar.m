classdef ReNoCar < matlab.System
    
    properties
        Delay         = 0;
        AllowCAR      = true;
        NewSampleRate = 512;
    end

    % Public, non-tunable properties
    properties(Nontunable)
        Method              = 'rate';
        
        SampleRate          = 3052;
        ResampleRate        = 512;
        Tolerance           = 1e-8;
        
        Capacity            = 1e5;
        
        Bandwidth           = 4;
        CenterFrequency     = 60;
        Cascade             = 'manual';
        
        Pairs               = {};
        nPairs              = 0;
        IncludeTarget       = true;
        mChan               = 2;
    end

    properties(DiscreteState)

    end

    % Pre-computed constants
    properties(Access = private)
        L            = 3;
        M            = 2;
        Numerator    = 10;
        BTA          = 5;
        pDelay       = 0;
        
        Harmonics    = 1;
        
        resamp
        notch
        pcar
    end

    methods
        % Constructor
        function obj = ReNoCar(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
            obj.nPairs = length(obj.Pairs);
            obj.buildSystemObjects();
        end
        
        function d = get.Delay(obj)
            d = obj.resamp.Delay;
        end
        
        function buildSystemObjects(obj)
            obj.resamp = Resample('Method', obj.Method, 'SampleRate', obj.SampleRate,...
                                  'ResampleRate', obj.ResampleRate, 'L', obj.L,...
                                  'M', obj.M, 'Numerator', obj.Numerator,...
                                  'BTA', obj.BTA);
            [obj.L, obj.M, obj.NewSampleRate] = obj.resamp.buildCoefficients();
            obj.notch = NotchFilter('SampleRate', obj.NewSampleRate,...
                                    'Bandwidth', obj.Bandwidth,...
                                    'CenterFrequency', obj.CenterFrequency,...
                                    'Cascade', obj.Cascade,...
                                    'Harmonics', obj.Harmonics);
            obj.pcar = CAR('Allow', obj.AllowCAR, 'Pairs', obj.Pairs,...
                           'IncludeTarget', true, 'mChan', obj.mChan);
        end
        
        function [re] = buildRePlots(obj, names, map, override)
            if ischar(names)
                names = {names};
            end
            if nargin < 4
                override = false;
            end

            re = obj.resamp.buildPlot(names, map, override);
        end

        function [no] = buildNoPlots(obj, names, map, override)
            if ischar(names)
                names = {names};
            end
            if nargin < 4
                override = false;
            end

            no = obj.notch.buildPlot(names, map, override);
        end

        function pcar = buildCarPlots(obj, names, map, override)
            if ischar(names)
                names = {names};
            end
            if nargin < 4
                override = false;
            end

            pcar = obj.pcar.buildPlot(names, map, override);
        end
        
        function plotTracking(obj, t)
            obj.resamp.plotTracking(t);
            obj.notch.plotTracking(t);
            obj.pcar.plotTracking(t);
        end
    end

    methods(Access = protected)
        %% Common functions
        function setupImpl(obj)
            if isempty(obj.resamp) || isempty(obj.notch) || isempty(obj.pcar)
                obj.buildSystemObjects();
            end
        end

        function [pc, nt, ds] = stepImpl(obj, u, time)
            ds = obj.resamp(u, time);
            if ~isempty(ds) 
                nt = obj.notch(ds, time);
                pc = obj.pcar(nt, time);
            else
                nt = [];
                pc = [];
            end
        end

        function resetImpl(obj)
            reset(obj.resamp);
            reset(obj.notch);
            reset(obj.pcar);
        end
    end
end
