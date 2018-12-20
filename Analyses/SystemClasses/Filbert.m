classdef Filbert < matlab.System

    % Public, non-tunable properties
    properties(Nontunable)
        Capacity     = 1e8;
        SampleRate   = 512;
        
        A            = 0.39;
        B            = 0.5;
        OctaveSpace  = 1/7;
        
        F0           = 0.018; 
        BandLimits   = [1 200];
        MinFrequency = 1;
        MaxFrequency = 200;
        
        LogFrequency = 4;
        IgnorBands   = [340 480; 720 890];
    end

    properties(DiscreteState)
        Buffer
    end

    % Pre-computed constants
    properties(Access = private)
        CenterFrequencies
        nCenterFrequencies
        
        SigmaFrequencies 
        SigmaRootTwo
    end

    methods
        % Constructor
        function obj = Filbert(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:});
            obj.setBandLimits(obj.BandLimits);
        end
        
        function setBandLimits(obj,limits)
            obj.BandLimits = limits;
            obj.MinFrequency = limits(1);
            obj.MaxFrequency = limits(2);
        end
        
        function c_fs = getCenterFrequencies(obj)
            c_fs = obj.CenterFrequencies;
        end
        
        function sigma_fs = getSigmaFrequencies(obj)
            sigma_fs = obj.SigmaFrequencies;
        end
        
        function [f, reject, pass] = removeBands(obj, x)
            reject = any(obj.IgnorBands(:,1)<x & x <obj.IgnorBands(:,2));
            pass = ~reject;
            f = x(pass);
        end
        
        function c_fs = buildCenterFrequencies(obj)
            % Pre Log Space Center Frequencies
            low  = obj.F0;
            last = obj.F0;
            
            while last < obj.LogFrequency
                last = last + obj.A*last^(obj.B);
                low  = [low, last];
            end
            
            % Log Space Center Frequencies
            first = low(end);
            n_max = floor(log2(obj.MaxFrequency/first) / obj.OctaveSpace); 
            
            high = first*2.^((1:n_max)*obj.OctaveSpace);
            
            % Combine Center Frequencies and Ingnor Select Bands
            [c_fs, ~, ~] = obj.removeBands([low(low>=obj.MinFrequency) high]);
            
            obj.CenterFrequencies  = c_fs;
            obj.nCenterFrequencies = length(c_fs);
        end
        
        function sigma_fs = buildSigmaFrequencies(obj)
            sigma_fs = obj.A * obj.CenterFrequencies .^ obj.B;
            sigma_ds = sigma_fs.*sqrt(2);
            
            obj.SigmaFrequencies = sigma_fs;
            obj.SigmaRootTwo     = sigma_ds;  
        end
    end

    methods(Access = protected)
        %% Common functions
        function setupImpl(obj)
            buildCenterFrequencies(obj);
            buildSigmaFrequencies(obj);
            obj.Buffer = dsp.AsyncBuffer(obj.Capacity);
        end

        function y = stepImpl(obj,u)
            % Initialize Variables 
            fs     = obj.SampleRate;
            cf     = obj.CenterFrequencies;
            n_cf   = obj.nCenterFrequencies;
            sd     = obj.SigmaRootTwo;
            buffer = obj.Buffer;
            y = [];
            
            % Check Total Samples
            write(buffer, u);
            bn = buffer.NumUnreadSamples;
            if bn > 1
                x = read(buffer, bn - mod(bn,2));
                [s, c] = size(x);
            else
                return
            end
            
            % Even Number of Samples
            h              = zeros(s,c);
            h([1 s/2+1],:) = 1;
            h(2:s/2)       = 2;
            
            % Create Frequency Range
            pf   = (0:s/2).* (fs/s);
            n_pf = length(pf);
            
            % Calculate Hilbert
            y  = NaN(s, c, n_cf);
            fx = fft(x,s,1);
            for i = 1:n_cf
                k = (pf-cf(i))./sd(i);
                
                coef               = zeros(s, c);
                coef(1:n_pf, :)    = exp( -0.5.* k.^2);
                coef(n_pf+1:end,:) = flipud(coef(2:s/2,:));
                coef(1,:)          = 0;
                
                y(:,:,i) = ifft(fx.*(coef.*h), s);
            end
        end

        function resetImpl(obj)
            obj.Buffer.reset();
        end
    end
end
