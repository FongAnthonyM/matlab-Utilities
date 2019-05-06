classdef realmultispec < realmultiplot
    
    properties
    
    end

    methods
        % Constructor
        function obj = realmultispec(varargin)
            % Support name-value pair arguments when constructing object
            x = varargin{1};
            y = varargin{2};
            varargin(1:2) = [];
            
            obj@realmultiplot(varargin{:});
            obj.Bmin      = 0;
            obj.Amin      = 0;
            obj.Vfra      = 0;
            
            obj.spectrograms(x, y);
        end
        
        function spectrograms(obj, x, y)
            temp = figure('Visible','off');
            spectro = pcolor(x, y, zeros(length(y),length(x)));
            spectro.MeshStyle = 'column';
            g_names = {'spectro'};
            g_parts = {spectro};
            
            obj.addGraphics('all', g_names, g_parts);
            close(temp);
            obj.Pfunc = @obj.addSpectrogramData;
        end
        
        function last = spectrogramData(obj, u, index, time, mapping, map)
            if mapping 
                u_ch = u(:, :, map(index(1),index(2)));
            else
                u_ch = u{index(1), index(2)};
            end
            % u_ch = [time, frequency]%
            if ~isempty(u_ch)
                x_ds = linspace(time(1), time(2), size(u_ch,1)+1);
                obj.Plots(index(1), index(2)).spectro.XData = x_ds;
                %obj.Plots(index(1), index(2)).subplot.XLim = time;
                obj.Plots(index(1), index(2)).spectro.CData = u_ch.';
                last = u_ch(end,:);
            else
                last = [];
            end
        end
        
        function last = addSpectrogramData(obj, u, index, time, mapping, map)
            if mapping 
                u_ch = u(:, :, map(index(1),index(2)));
            else
                u_ch = u{index(1), index(2)};
            end
            % u_ch = [time, frequency]%
            if ~isempty(u_ch)
                x_ds = linspace(time(1), time(2), size(u_ch,1)+1);
                obj.Plots(index(1), index(2)).spectro.XData = x_ds;
                %obj.Plots(index(1), index(2)).subplot.XLim = time;
                obj.Plots(index(1), index(2)).spectro.CData = u_ch.';
                last = u_ch(end,:);
            else
                last = [];
            end
        end
    end
end
