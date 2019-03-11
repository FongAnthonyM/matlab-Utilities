classdef Resample < matlab.System
% Resample

    properties
        L             = 3;
        M             = 2;
        Numerator     = 10;
        BTA           = 5;
        Delay         = 0;
        NewSampleRate = 512;
    end

    % Public, non-tunable properties
    properties(Nontunable)
        Method       = 'rate';
        
        SampleRate   = 3052;
        ResampleRate = 512;
        Tolerance    = 1e-5;
        
        Capacity     = 1e5;
        
        DataStructPresent = false; 
        DataStruct
        
        PlotPresent  = false;
        ChannelMap   = [];
        Plot
    end
    
    properties(Access = private)
        pDelay       = 0;
        
        Buffer
        FIRRC
    end
    
    properties(DiscreteState)
        FirstOffset
    end

    properties(Constant, Hidden)
        MethodSet = matlab.system.StringSet({'rate', 'ratio'});
    end
    
    methods
        % Constructor
        function obj = Resample(varargin)
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
                plt = realmultiplot([600 length(names)*150], names, 'Name', 'Resample', 'Visible', 'off');
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
        
        function [h, d] = buildFIR(obj, p, q, N, bta)
        % buildFIR
        % Builds an FIR in the same way resample does.
            if nargin < 5
                bta = 5;
            end   %--- design parameter for Kaiser window LPF
            if nargin < 4 
                N = 10;
            end
            
            pqmax = max(p,q);
            if length(N)>1      % use input filter
               h = N;
            else                % design filter
               if( N>0 )
                  fc = 1/2/pqmax;
                  L = 2*N*pqmax + 1;
                  h = firls(L-1, [0 2*fc 2*fc 1], [1 1 0 0]).*kaiser(L,bta)' ;
                  h = p*h/sum(h);
               else
                  h = ones(1,p);
               end
            end
            
            d = round(length(h)/2/obj.M);
        end
        
        function [L, M, n_s] = buildCoefficients(obj)
        % buildCoefficients
            if strcmpi(obj.Method, 'rate')
                x = obj.ResampleRate/obj.SampleRate;
                [L, M] = rat(x, obj.Tolerance);
            else
                L = obj.L;
                M = obj.M;
            end
            n_s = obj.SampleRate*L/M;
            obj.L = L;
            obj.M = M;
            obj.NewSampleRate = n_s;
        end
    end

    methods(Access = protected)
        %% ---- Implementation Functions ---- %%
        function setupImpl(obj)
        % setupImpl    
            obj.buildCoefficients();
            
            [obj.Numerator, delay] = obj.buildFIR(obj.L, obj.M, obj.Numerator, obj.BTA);
            obj.Delay  = delay;
            obj.pDelay = delay;
            obj.FIRRC  = dsp.FIRRateConverter(obj.L, obj.M, obj.Numerator);
            obj.Buffer = dsp.AsyncBuffer(obj.Capacity);
            obj.FirstOffset = true;
        end

        function y = stepImpl(obj, u, time)
        % stepImpl
            m      = obj.M;
            buffer = obj.Buffer;
            firrc  = obj.FIRRC;
            map    = obj.ChannelMap;
            y      = [];
            
            write(buffer, u);
            while buffer.NumUnreadSamples >= m
                x = read(buffer,m);
                y = [y; firrc(x)];
            end
            
            if ~isempty(y)
                if obj.FirstOffset
                    y = y(obj.pDelay+1:end, :);
                    obj.FirstOffset = false;
                end
                
                if obj.DataStructPresent
                    [sam, cha] = size(y);
                    self.DataStruct.appendDataNaNList(mat2cell(y,sam,ones(1,cha)),1);
                end
                
                if obj.PlotPresent
                    obj.Plot(y, time, map);
                end
            end
        end

        function resetImpl(obj)
        % resetImpl
            if strcmpi(obj.Method, 'rate')
                obj.buildCoefficients();
            end
            
            [obj.Numerator, obj.Delay] = obj.buildFIR(obj.L, obj.M, obj.Numerator, obj.BTA);
            obj.FIRRC = dsp.FIRRateConverter(obj.L, obj.M, obj.Numerator);
            obj.Buffer = dsp.AsyncBuffer(obj.Capacity);
            obj.FirstOffset = true;
        end
        
    end
end
