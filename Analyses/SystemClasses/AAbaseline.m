classdef AAbaseline < matlab.System

    % Public, non-tunable properties
    properties(Nontunable)
        Name = 'AAbaseline'
        Multiprocessing = false;
        
 
        
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
        function obj = AAbaseline(varargin)
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

        function varargout = stepImpl(obj, x, time)
            map = obj.ChannelMap;

            for index = 1:length(c_list)
                region = c_list{index};
                [ ~, ~, m_hx, ~ ] = filbert(car_r.(region).', self.filters);
                % [Sample, Channel, Band]
                amp = permute(m_hx, [2,1,3]);
                ba_amp.(region) = amp;
                % [Channel, Sample, Band]
                for j = 1:self.n_bins
                    st = (j-1)*self.bin_sn + 1;
                    ed = j*self.bin_sn;
                    frame = amp(:,st:ed,:);
                    f_mean(:,:,j) = squeeze(nanmean(frame,2));
                end
                z_mean.(region) = squeeze(nanmean(f_mean,3));
                z_s.(region) = squeeze(std(f_mean,0,3));
            end

            
            if obj.PlotPresent
                obj.Plot('result', time, map)
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
