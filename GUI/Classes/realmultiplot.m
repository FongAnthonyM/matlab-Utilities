classdef realmultiplot < scrollmultiplot & matlab.System
    
    properties
        Bmin      = 1;
        Amin      = 1;
        MaxPoints = 1e4;
        Text      = false;
        Track     = true;
    end

    % Pre-computed constants
    properties(Access = private)
        Plots
    end

    methods
        % Constructor
        function obj = realmultiplot(varargin)
            % Support name-value pair arguments when constructing object
            obj@scrollmultiplot(varargin{:}); 
        end
        
        function lineplots(obj)
            temp = figure('Visible','off');
            animeline = animatedline('MaximumNumPoints',obj.MaxPoints);
            ptext = text(0, 0, ' ', 'Color', 'b', 'Visible', 'off');
            g_names = {'animeline', 'ptext'};
            g_parts = {animeline, ptext};
            
            obj.addGraphics('all', g_names, g_parts);
            close(temp);
            obj.Plots = obj.plots;
        end
        
        function last = addLinePlotData(obj, u, index, time, mapping, map)
            if mapping 
                u_ch = u(:, map(index(1),index(2)));
            else
                u_ch = u{index(1), index(2)};
            end
            %y_ch = resample(y{index}, 1, rs_factor);
            x_ds = linspace(time(1), time(2), length(u_ch));
            obj.Plots(index(1), index(2)).animeline.addpoints(x_ds, u_ch);
            last = u_ch(end);
        end
        
        function spectrograms(obj, x, y)
            temp = figure('Visible','off');
            spectro = pcolor(x, y, zeros(length(x),length(y)));
            ptext = text(0, 0, ' ', 'Color', 'b', 'Visible', 'off');
            g_names = {'spectro', 'ptext'};
            g_parts = {spectro, ptext};
            obj.addGraphics('all', g_names, g_parts);
            close(temp);
            obj.Plots = obj.plots;
        end
        
        function last = addSpectrogramData(obj, u, index, time, mapping)
            if mapping 
                u_ch = u(:, :, map(index(1),index(2)));
            else
                u_ch = u{index(1), index(2)};
            end
            %y_ch = resample(y{index}, 1, rs_factor);
            x_ds = linspace(time(1), time(2), length(u_ch));
            obj.Plots(index(1), index(2)).animeline.addpoints(x_ds, u_ch);
            last = u_ch(end);
        end
        
        function setPlotEnds(self, lims)
            self.Bmin = lims(1);
            self.Amin = lims(2);
        end
        
        function pointText(obj, allow)
            if allow
                obj.Text = true;
                vis = 'on';
            else
                obj.Text = false;
                vis = 'off';
            end
            shape = obj.shape;
            for i = 1:shape(1)
                for j = 1:shape(2)
                    set(obj.Plots(i,j).ptext, 'Visible', vis);
                end
            end
        end
    end

    methods(Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            obj.Track = true;
            obj.Plots = obj.plots;
        end

        function stepImpl(obj, u, time, map)
            if nargin < 3 || isempty(map)
                mapping = false;
                map = [];
            else
                mapping = true;
            end
            
            if length(time) == 2
                start = time(1);
                stop  = time(2);
            else
                start = time;
                stop  = time; 
            end
            
            txt   = obj.Text;
            track = obj.Track;
            shape = obj.shape;
            b_min = obj.Bmin;
            a_min = obj.Amin;
            
            offset = (stop - start)*.10;
            bof = max([offset b_min]);
            aof = max([offset a_min]);
            
            for i = 1:shape(1)
                for j = 1:shape(2)
                    last = obj.addLinePlotData(u, [i,j], time, mapping, map);
                    if txt
                        set(obj.Plots(i,j).ptext, 'Position', [time last]);
                        set(obj.Plots(i,j).ptext, 'String', ['\leftarrow ' sprintf('%2.4f', last)]);
                    end
                    if track 
                        xlim(obj.Plots(i,j).subplot, [start-bof stop+aof]);
                    end
                end
            end
            drawnow limitrate
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.Track = true;
        end


    end
end
