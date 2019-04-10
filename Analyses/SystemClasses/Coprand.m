classdef Coprand < matlab.System

    % Public, non-tunable properties
    properties(Nontunable)
        Multiprocessing = false;
        
        Window     = [];
        Noverlap   = [];
        NFFT       = [];
        W          = [];
        MIMO       = [];
        F          = [];
        SampleRate = [];
        Freqrange  = [];   
        
        Surrogates = 3;
        
        coherence
        phasecoher
        
        CoherencePlotPresent = false;
        CoherenceMap         = [];
        CoherencePlot
        AveragePlotPresent = false;
        AverageMap
        AveragePlot
    end
    
    properties(Access = private)
        Ppool
        Pcohere
    end

    methods
        % Constructor
        function obj = Coprand(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
            obj.setMultiprocessing();
        end
        
        function setMultiprocessing(obj)
            if obj.Multiprocessing
                obj.Pcohere = @obj.parpcohere;
                if isempty(gcp('nocreate'))
                    obj.Ppool = parpool('local',4);
                end
            else
                obj.Pcohere = @obj.phasecohere;
            end
        end
        
        function buildSystemObjects(obj)
            obj.coherence = Coherence('Multiprocessing', obj.Multiprocessing,...
                                      'Window', obj.Window,...
                                      'Noverlap', obj.Noverlap,...
                                      'NFFT', obj.NFFT, 'W', obj.W,...
                                      'MIMO', obj.MIMO, 'F', obj.F,...
                                      'SampleRate', obj.SampleRate,...
                                      'Freqrange', obj.Freqrange);
            obj.phasecoher = Coherence('Multiprocessing', false,...
                                       'Window', obj.Window,...
                                       'Noverlap', obj.Noverlap,...
                                       'NFFT', obj.NFFT, 'W', obj.W,...
                                       'MIMO', obj.MIMO, 'F', obj.F,...
                                       'SampleRate', obj.SampleRate,...
                                       'Freqrange', obj.Freqrange);
        end
        
        function plt = buildCoPlot(obj, names, map, override)
            if ischar(names)
                names = {names};
            end
            if nargin < 4
                override = false;
            end
            
            if override || isempty(obj.CoherencePlot)
                plt = realmultiplot([600 length(names)*150], names, 'Name', 'Coherence', 'Visible', 'off');
                plt.lineplots();
                plt.setLabels('all', 'Time [s]', 'Coherence');
                plt.setLimits('all', [0 1], [0 1]);
                plt.pointText(true);
                obj.CoherencePlot = plt;
                obj.CoherenceMap = map;
            else
                plt = obj.CoherencePlot;
            end
            obj.CoherencePlotPresent = true;
        end
        
        function plt = buildAvPlot(obj, names, map, override)
            if ischar(names)
                names = {names};
            end
            if nargin < 4
                override = false;
            end
            
            if override || isempty(obj.AveragePlot)
                plt = realmultiplot([600 length(names)*300], names, 'Name', 'Average Coherence', 'Visible', 'off');
                plt.lineplots();
                plt.setLabels('all', 'Time [s]', 'Coherence');
                plt.setLimits('all', [0 1], [0 1]);
                plt.pointText(true);
                obj.AveragePlot = plt;
                obj.AverageMap = map;
            else
                plt = obj.AveragePlot;
            end
            obj.AveragePlotPresent = true;
        end
        
        function plotTracking(obj, t)
            if obj.CoherencePlotPresent
                obj.CoherencePlot.Track = t;
            end
            if obj.AveragePlotPresent
                obj.AveragePlot.Track = t;
            end
        end
    end

    methods(Access = protected)
        %% Common functions
        function setupImpl(obj)
            if isempty(obj.coherence) || isempty(obj.phasecoher)
                obj.buildSystemObjects();
            end
           obj.setMultiprocessing();
        end

        function [c_yx, ac_yx, pcf, a_pcf, a_pc, adj_c, aa_c] = stepImpl(obj, x, y, time)
            c_map = obj.CoherenceMap;
            a_map = obj.AverageMap;
            surr = obj.Surrogates;

            % Phase Random Surrogates (Sample, Channel, Surrogate)
            p_x = phaseRandom(x, surr);
            p_y = phaseRandom(y, surr);
            
            % Coherence (Y, X, Frequency)
            % Average Freq Coherence(Y, X)
            [c_yx, ~] = obj.coherence(x, y, time);
            ac_yx = nanmean(c_yx, 3);
            
            % Phase Random Freq Coherence (Y, X, Freq, Surragate)
            % Average Pran Freq Coherence (Y, X, Surragate)
            [pcf, a_pcf] = obj.Pcohere(p_x, p_y, time);
            
            % Average Phase Random Coherence (Y, X)
            a_pc = nanmean(a_pcf, 3);
            
            % Adjusted Coherence (Y, X)
            adj_c = ac_yx - a_pc;
            aa_c = nanmean(nanmean(adj_c));
            
            if obj.CoherencePlotPresent
                % Reshaped Adjusted Coherence [Y, X] to vector X*[Y]
                % [Y,X] Map is made with reshape(1:(Y*X),[Y,X]) 
                obj.CoherencePlot(reshape(adj_c,[1,numel(adj_c)]), time, c_map);
            end
            
            if obj.AveragePlotPresent
                obj.AveragePlot(aa_c, time, a_map);
            end
        end

        function resetImpl(obj)
           reset(obj.coherence);
           reset(obj.phasecoher);
           obj.setMultiprocessing();
        end
        
        function [pcf, a_pcf] = phasecohere(obj, x, y, time)
            frange = obj.F;
            cohere = obj.phasecoher;
            surr = obj.Surrogates;
            n_x = size(x,2);
            n_y = size(y,2);
            pcf = NaN(n_y, n_x, length(frange), surr);
            a_pcf = NaN(n_y, n_x, surr);
            for s = 1:surr
                [pc, ~] = cohere(x(:,:,s), y(:,:,s), time);
                pcf(:,:,:,s) = pc;
                a_pcf(:,:,s) = nanmean(pc,3);
            end
        end
        
        function [pcf, a_pcf] = parpcohere(obj, x, y, time)
            frange = obj.F;
            cohere = obj.phasecoher;
            surr = obj.Surrogates;
            n_x = size(x,2);
            n_y = size(y,2);
            pcf = NaN(n_y, n_x, length(frange), surr);
            a_pcf = NaN(n_y, n_x, surr);
            parfor s = 1:surr
                [pc, ~] = cohere(x(:,:,s), y(:,:,s), time);
                pcf(:,:,:,s) = pc;
                a_pcf(:,:,s) = nanmean(pc,3);
            end
        end
    end
end
