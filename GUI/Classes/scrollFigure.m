classdef scrollFigure < figureContainer
   
properties
    parent
    child
    
    sizeFcn
    Units
    Position
    BackgroundColor
    
    panes
    panels
    plimit = 2160
    
    pan_pos
    o_size
    t_size
    Xs_size
    Ys_size
    Xinc
    Yinc
    bar_w
    tick
    
    Xslider
    Xs_pos
    Xsf
    
    Yslider
    Ys_pos
    Ysf
end

methods
    %% ---- Methods ---- %%
    function self = scrollFigure(varargin)
        if isempty(varargin) || isa(varargin{1}, 'char')
            loc = [800 800];
        else
            old_fig = [];
            if isa(varargin{1}, 'handle') || isa(varargin{1}, 'struct') || isa(varargin{1}, 'cell')
                old_fig = varargin{2};
                varargin(1) = [];
            end
            loc = varargin{1};
            varargin(1) = [];
        end
        self.o_size = loc;
        
        [size_pres, size_loc] = ismember('SizeChangedFcn', varargin(1:2:end));
        if size_pres
            self.sizeFcn = varargin(size_loc+1);
            varargin(size_loc+1) = {@sizeChange};
        else
            varargin(end+1) = {'SizeChangedFcn'};
            varargin(end+1) = {@sizeChange};
        end
        
        self.bar_w = 10;
        self.tick = 10;
        self.panes = floor(loc(2)/2160)+1;
        l_pane = rem(loc(2), 2160);
        if self.panes == 1
            self.t_size = loc + self.bar_w;
        else
            self.t_size = [loc(1) self.panes*2160] + self.bar_w;
        end
        
        self.fig = figure(varargin{:});
        self.Units = self.fig.Units;
        self.Position = self.fig.Position;
        self.BackgroundColor = self.fig.Color;

        self.fig.Units = 'pixels';
        fpos = self.Position;
        
        if self.panes == 1
            self.pan_pos(1,:) = [0 fpos(4)-loc(2) loc];
            self.panels = uipanel(self.fig, 'Units', 'pixels', 'Position', self.pan_pos(1,:),'BackgroundColor',self.BackgroundColor);
        else
            self.pan_pos(1,:) = [0 fpos(4)-(2160) loc(1) 2160];
            self.panels = gobjects();
            for i = 1:self.panes
                self.pan_pos(i,:) = [0 fpos(4)-(2160*i) loc(1) 2160];
                self.panels(i) = uipanel(self.fig, 'Units', 'pixels', 'Position', self.pan_pos(i,:),'BackgroundColor',self.BackgroundColor);
            end
        end
        
        if ~isempty(old_fig)
            if isa(old_fig, 'handle')
                setGraphFig(self, old_fig);
            else
                setGraphics(self, old_fig);
            end
        end
        
        self.setSliders(fpos(3), fpos(4));
        
        self.Xslider = uicontrol('Style', 'slider', 'Min', 0, 'Max', self.Xinc, 'Value', 0, ...
                                 'Unit', 'pixel', 'Position', self.Xs_pos, 'Callback', @xSlide);
        self.Yslider = uicontrol('Style', 'slider', 'Min', -self.Yinc, 'Max', 0, 'Value', 0, ...
                                 'Units', 'pixel', 'Position', self.Ys_pos, 'Callback', @ySlide);
        
        self.fig.Units = self.Units;
                             
                             
        function sizeChange(f,callbackdata)
            old_units = f.Units;
            f.Units = 'pixels';
            fpos = f.Position;
            
            old_inc = [self.Xinc self.Yinc];
            self.setSliders(fpos(3), fpos(4));
            
            self.Xslider.Position = self.Xs_pos;
            self.Xslider.Max = self.Xinc;
            self.Yslider.Position = self.Ys_pos;
            self.Yslider.Min = -self.Yinc;
            self.Position = fpos;
            
            if ~isempty(old_inc)
                if old_inc(1) == 0
                    x_scaler = 0;
                else
                    x_scaler = self.Xinc/old_inc(1);
                end
                self.Xslider.Value = adjustSvalue(self, self.Xslider.Value, x_scaler, 0, self.Xinc);
                if old_inc(2) == 0
                    y_scaler = 0;
                else
                    y_scaler = self.Yinc/old_inc(2);
                end
                self.Yslider.Value = adjustSvalue(self, self.Yslider.Value, y_scaler, -self.Yinc, 0);
            end
            
            if ~isempty(self.panels)
                for j = 1:length(self.panels)
                    ploc = self.pan_pos(j,:);
                    yscale = self.Yslider.Value;
                    ploc(2) = fpos(4) - j*ploc(4) - yscale*self.Ysf;
                    self.pan_pos(j,:) = ploc;
                    self.panels(j).Position = self.pan_pos(j,:);
                end
            end
            
            f.Units = old_units;
            
            if isa(self.sizeFcn, 'handle')
                self.sizeFcn(f, callbackdata)
            end
        end
        
        function xSlide(slider, event)
            scale = slider.Value;
            if scale < slider.Min
                scale = slider.Min;
                slider.Value = slider.Min;
            elseif scale > slider.Max
                scale = slider.Max;
                slider.Value = slider.Max;
            end
            for k = 1:length(self.panels)
                location = self.panels(k).Position;
                location(1) = (-scale)*self.Xsf;
                self.pan_pos(k,:) = location;
                self.panels(k).Position = location;
            end
        end
        
        function ySlide(slider, event)
            fh = self.Position(4);
            scale = slider.Value;
            if scale < slider.Min
                scale = slider.Min;
                slider.Value = slider.Min;
            elseif scale > slider.Max
                scale = slider.Max;
                slider.Value = slider.Max;
            end
            for l = 1:length(self.panels)
                location = self.panels(l).Position;
                location(2) = fh-(l*location(4))-(scale)*self.Ysf;
                self.pan_pos(l,:) = location;
                self.panels(l).Position = location;
            end
        end
    end
    
    function [X,Y] = setSliders(self, w, h)
        if w-self.bar_w > 0, xw = w-self.bar_w; else xw = 0; end
        if h-self.bar_w > 0, yh = h-self.bar_w; else yh = 0; end
        Xs_pos = [0 0 xw self.bar_w];
        Ys_pos = [w-self.bar_w self.bar_w self.bar_w yh];
        
        Xs = self.t_size(1) - w; 
        if Xs > 0, Xs_size = Xs; else Xs_size = 0; end
        Xi = floor((Xs_size/w)*self.tick);
        if Xi > 0
            Xinc = Xi;
            Xsf = ceil((Xs_size)/Xinc);
        else
            Xinc = 0;
            Xsf = 0;
        end
        
        
        Ys = self.t_size(2)-h;
        if Ys > 0, Ys_size = Ys; else Ys_size = 0; end
        Yi = floor((Ys_size/h)*self.tick);
        if Yi > 0
            Yinc = Yi;
            Ysf = ceil(Ys_size/Yinc);
        else
            Yinc = 0; 
            Ysf = 0;
        end
        
        
        self.Xs_pos = Xs_pos;
        self.Xinc = Xinc;
        self.Xsf = Xsf;
        
        self.Ys_pos = Ys_pos;
        self.Yinc = Yinc;
        self.Ysf = Ysf;
        X = [Xs_pos, Xinc, Xsf];
        Y = [Ys_pos, Yinc, Ysf];
    end
    
    function [value] = adjustSvalue(self, v, scaler, min, max)
        new = v*scaler;
        if new < min
            value = min;
        elseif new > max
            value = max;
        else
            value = new;
        end
    end
    
    function setGraphFig(self, fig)
        graphics = fig.Children;
        for i = 1:length(graphics)
            set(graphics, 'Parent', self.panels);
        end
    end
    
    function setGraphics(self, group)
        [m, n] = size(group);
        for i = 1:m
            for j = 1:n
                set(group{i,j}, 'Parent', self.panels)
            end
        end
    end
    
    function addAxes(self, axs)
        [m, n] = size(axs);
        
        phs = ceil(m/self.panes);
        
        sub_w = (1/n) * 1;
        sub_h = (1/phs) * 1;
        g_w = (1/n) * 0;
        g_h = (1/phs) * 0;
        
        for p = 1:self.panes
            mane = self.panels(p);
            for i = 1:phs
                a = phs*(p-1) + i;
                if a > m
                    break
                end
                for j = 1:n
                    ax = axs(a,j);
                    
                    set(ax, 'Parent', mane);
                    u = ax.Units;
                    ax.Units = 'normalized';
                    x = 1*(j-1)/n + g_w;
                    y = 1*(1-(i/phs)) - g_h;
                    subp = [x, y, sub_w, sub_h];
                    ax.OuterPosition = subp;
                    ax.Units = u;
                end
            end
        end
    end
end

end

