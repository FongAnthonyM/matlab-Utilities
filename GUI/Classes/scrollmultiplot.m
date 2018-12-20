classdef scrollmultiplot < multiplot & scrollFigure
    
properties  
end

methods
    function self = scrollmultiplot(varargin)
        old_fig = [];
        if isempty(varargin) || isa(varargin{1}, 'char')
            loc = [800 800];
            list = {};
        else
            if isa(varargin{1}, 'handle') || isa(varargin{1}, 'struct') || isa(varargin{1}, 'cell')
                old_fig = varargin{1};
                varargin(1) = [];
            end
            loc = varargin{1};
            list = varargin{2};
            if ischar(list)
                list = {list};
            end
            varargin([1,2]) = [];
        end
        
        if isempty(old_fig)
            args = [loc, varargin];
        else
            args = [old_fig, loc, varargin];
        end
        
        self@scrollFigure(args{:});
        self.addMultiPlots(list);
    end
    
    function addMultiPlots(self, list)
        if ischar(list)
            list = {list};
        end
        [m, n] = size(list);
        self.shape = [m, n];
        
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
                    if isstruct(list{a,j})||ischar(list{a,j})
                        ax = axes('Parent',mane,'Units','normalized');
                        x = 1*(j-1)/n + g_w;
                        y = 1*(1-(i/phs)) - g_h;
                        subp = [x, y, sub_w, sub_h];
                        ax.OuterPosition = subp;
                        self.subplots(a,j) = ax;
                        self.plots(a,j).subplot = ax;
                    else
                        continue
                    end
                    
                    if isstruct(list)
                        if isstruct(list(a,j).args)
                            fields = fieldnames(list(a,j).args);
                            self.plots(a,j).name = list(a,j).args.Title;
                            for index = 1:length(fields)
                                if strcmp(fields{index},'Title')
                                    title(list(a,j).args.Title);
                                elseif strcmp(fields{index},'XLabel')
                                    xlabel(list(a,j).args.XLabel);
                                elseif strcmp(fields{index},'YLabel')    
                                    ylabel(list(a,j).args.YLabel);
                                elseif strcmp(fields{index},'ZLabel')
                                    zlabel(list(a,j).args.ZLabel);
                                else
                                    set(ax.subplot, (fields{index}), list(a,j).args.(fields{index}));
                                end
                            end
                        end
                    else
                        title(list{a,j});
                        self.plots(a,j).name = list{i,j};
                    end
                end
            end
        end
    end
end
    
end

