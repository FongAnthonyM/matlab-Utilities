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
            obj.defaultFigures(); 
        end
        
        function defaultFigures(obj)
            temp = figure('Visible','off');
            animeline = animatedline('MaximumNumPoints',obj.MaxPoints);
            ptext = text(0, 0, ' ', 'Color', 'b', 'Visible', 'off');
            g_names = {'animeline', 'ptext'};
            g_parts = {animeline, ptext};
            obj.addGraphics('all', g_names, g_parts);
            close(temp);
            obj.Plots = obj.plots;
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
                    if mapping 
                        u_ch = u(:,map(i, j));
                    else
                        u_ch = u{i,j};
                    end
                    %y_ch = resample(y{index}, 1, rs_factor);
                    x_ds = linspace(start, stop, length(u_ch));
                    obj.Plots(i,j).animeline.addpoints(x_ds, u_ch);
                    if txt
                        set(obj.Plots(i,j).ptext, 'Position', [time u_ch(end)]);
                        set(obj.Plots(i,j).ptext, 'String', ['\leftarrow ' sprintf('%2.4f', u_ch(end))]);
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
