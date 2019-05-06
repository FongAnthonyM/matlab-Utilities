classdef multiplot < figureContainer
properties
    plots
    subplots
    list
    shape
end
    
methods
    function self = multiplot(list, parent, vis)
        
        if nargin == 1
            createPlots(self, list);
        elseif nargin == 2
            createPlots(self, list, parent);
        elseif nargin == 3
            createPlots(self, list, parent, vis);
        end
        
    end
    
    function [ out ] = createPlots(self, list, parent, vis)
    % createPlots
    %   Creates subplots in a structure
    %   Input
    %   :list:      structure/cell array    An array of plot names whose shape will determine the subplot settings
    %   :parent:    handle/string           Either the handle to figure to place the plots
    %                                       or the name for the new figure
    %   :vis:       boolean                 Choose the visiblity of the figure    
        % Set parent and visiblity 
        self.list = list;
        [m, n] = size(list);
        self.shape = [m, n];
        if ischar(parent)
            if nargin > 3 && ~vis
                v = 'off';
            else
                v = 'on';
            end
            parent = figure('Name', parent, 'Visible', v);
        end
        sub_w = (1/n) * (1 - .2);
        sub_h = (1/m) * (1 - .2);
        g_w = (1/n) * .1;
        g_h = (1/m) * .2;

        self.subplots = gobjects();
        for i = 1:m
            for j = 1:n
                if isstruct(list{a,j})||ischar(list{a,j})
                    ax = axes('Parent',parent,'Units','normalized');
                    x = (j-1)/n + g_w;
                    y = 1-(i/m) - g_h;
                    subp = [x, y, sub_w, sub_h];
                    ax.OuterPosition = subp;
                    self.subplots(i,j) = ax;
                    self.plots(i,j).subplot = ax;
                else
                    continue
                end

                if isstruct(list)
                    if isstruct(list(i,j).args)
                        fields = fieldnames(list(i,j).args);
                        self.plots(i,j).name = list(i,j).args.Title;
                        for index = 1:length(fields)
                            if strcmp(fields{index},'Title')
                                title(list(i,j).args.Title);
                            elseif strcmp(fields{index},'XLabel')
                                xlabel(list(i,j).args.XLabel);
                            elseif strcmp(fields{index},'YLabel')    
                                ylabel(list(i,j).args.YLabel);
                            elseif strcmp(fields{index},'ZLabel')
                                zlabel(list(i,j).args.ZLabel);
                            else
                                set(self.plots(i,j).subplot, (fields{index}), list(i,j).args.(fields{index}));
                            end
                        end
                    end
                else
                    if ischar(list{i,j})
                        title(list{i,j})
                        self.plots(i,j).name = list{i,j};
                    end
                end
            end
        end
        out = self.plots;
        self.fig = parent;
    end

    function parent = setParent(self, parent, del)
    % setParent
    %   Set the plot of the panel
    %   Input
    %   :self:      handle                  A handle that points to the eventTimer object
    %   :parent:    handle                  Either the handle to figure to place the plots
    %   :del:       boolean                 Choose to delete the previous figure 
        [m, n] = size(self.plots);
        for i = 1:m
            for j = 1:n
                set(self.plots(i,j).subplot, 'Parent', parent);
            end
        end
        if nargin > 2 && del
            delete(self.fig);
        end
        self.fig = parent; 
    end
    
    function addGraphics(self, indices, names, items)
        if ~isequal(size(names), size(items)) && ~(isvector(names) && isvector(items) && numel(names) == numel(items))
            error('names and items must be the same size.')
        end
        
        if ischar(indices)
            [a,b] = size(self.plots);
            m = 1:a;
            n = 1:b;
        else
            m = indices(:,1);
            n = indices(:,2);
        end
        
        
        for i = m
            for j = n
                p = self.plots(i,j).subplot;
                for k = 1:length(names) 
                    if isa(items{k},'matlab.graphics.animation.AnimatedLine')
                        nline = animatedline();
                        nline.Parent = p;
                        nline.Color = items{k}.Color;
                        nline.LineWidth = items{k}.LineWidth;
                        nline.Marker = items{k}.Marker;
                        nline.MarkerSize = items{k}.MarkerSize;
                        nline.MarkerFaceColor = items{k}.MarkerFaceColor;
                        nline.MaximumNumPoints = items{k}.MaximumNumPoints;
                        self.plots(i,j).(names{k}) = nline;
                    else
                        self.plots(i,j).(names{k}) = copyobj(items{k}, p);
                    end
                end
            end
        end
    end
    
    function setLabels(self, indices, x, y, xt, yt)
        if ischar(indices)
            [a,b] = size(self.plots);
            m = 1:a;
            n = 1:b;
        else
            m = indices(:,1);
            n = indices(:,2);
        end
        
        for i = m
            for j = n
                parent = self.plots(i,j).subplot;
                if ~isempty(parent)
                    xlabel(parent, x)
                    ylabel(parent, y)
                    if nargin > 4
                        parent.XTick = xt;
                    end
                    if nargin > 5
                        parent.YTick = yt;
                    end
                end
            end
        end
    end
    
    function setLimits(self, indices, x, y)
        if ischar(indices)
            [a,b] = size(self.plots);
            m = 1:a;
            n = 1:b;
        else
            m = indices(:,1);
            n = indices(:,2);
        end
        
        for i = m
            for j = n
                parent = self.plots(i,j).subplot;
                if ~isempty(parent)
                    xlim(parent, x);
                    if nargin > 3
                        ylim(parent, y);
                    end
                end
            end
        end
    end
end
    
end

