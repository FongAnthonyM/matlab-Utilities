classdef dockGroup < handle
    properties
        name
        dims
        j_dims
        visible
        merge
        docked
        mode
        
        figs
        indices
        
        desktop
        hGroup
        hContainer
        tilepane
    end
    
    methods
        %% ---- Methods ---- %%
        function self = dockGroup(name, dims, figs, indices, merge, visible, docked, mode)
            try
                % Check inputs
                narginchk(1,8);

                % Require Java engine to run
                if ~usejava('jvm')
                    error([mfilename ' requires Java to run.']);
                end
                self.desktop = getDesktop(self);  % = com.mathworks.mde.desk.MLDesktop.getInstance;

                % Create Group
                self.name = name;
                if ischar(self.name)
                    self.hGroup = createGroup(self, self.name);
                else
                    error('Must supply a valid group name');
                end
                
                % Set Dims
                self.dims = dims;
                if isa(dims, 'double') && length(dims) == 2
                    self.j_dims   = java.awt.Dimension(dims(2), dims(1));
                else
                    error('Must supply valid group dimensions');
                end
                
                % Get Figures
                if nargin < 3
                    figs = [];
                else
                    if all(all(ishghandle(figs)))
                        self.figs = figs;
                    elseif iscell(figs)
                        
                    else
                        error('Figs must be valid GUI handles or cell array of handles');
                    end
                end
                
                if nargin < 4
                    indices = [];
                end
                self.indices = indices;
                
                if nargin < 5
                    merge = false;
                end
                self.merge = merge;
                
                if nargin < 6
                    visible = true;
                end
                self.visible = visible;
                
                if nargin < 7
                    docked = false;
                end
                
                if nargin < 8
                    mode = 2;
                end
                
                groupWindowSetup(self, dims, docked, mode)
                if isempty(figs)
                    emptyContainer(self);
                elseif all(all(ishghandle(figs))) && isempty(indices) && visible
                    populatedContainer(self, self.figs, visible)
                elseif all( all(ishghandle(figs))) && visible
                    positionedContainer(self, self.figs, indices, merge)
                elseif iscell(figs)
                    [self.figs, self.indices] = parseCell(self, figs);
                    if visible
                        positionedContainer(self, self.figs, self.indices, merge);
                    end
                end
            % Error handling
            catch
                handleErrorMessage(self);
            end
        end

        % Get the Java desktop reference
        function desktop = getDesktop(self)
            try
                desktop = com.mathworks.mde.desk.MLDesktop.getInstance;      % Matlab 7+
            catch
                desktop = com.mathworks.ide.desktop.MLDesktop.getMLDesktop;  % Matlab 6
            end
        end
        
        % Get the Matlab HG figure handle for a given handle
        function hFig = getHFig(self, handle)
            hFig = ancestor(handle,'figure');
            if isempty(hFig)
                error(['Cannot retrieve the figure handle for handle ' num2str(handle)]);
            end
        end

        % Get the root Java frame (up to 10 tries, to wait for figure to become responsive)
        function jframe = getJFrame(self, hFigHandle)
            % Ensure that hFig is a figure handle...
            hFig = getHFig(self, hFigHandle);
            hhFig = handle(hFig);

            jframe = [];
            maxTries = 10;
            oldWarn = warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
            while maxTries > 0
                try
                    % Get the figure's underlying Java frame
                    jframe = get(handle(hhFig),'JavaFrame');
                    if ~isempty(jframe)
                        break;
                    else
                        maxTries = maxTries - 1;
                        drawnow; pause(0.1);
                    end
                catch
                    maxTries = maxTries - 1;
                    drawnow; pause(0.1);
                end
            end
            warning(oldWarn);
            if isempty(jframe)
              error(['Cannot retrieve the java frame for handle ' num2str(hFigHandle)]);
            end
        end
        
        % Create a group
        function ghandle = createGroup(self, name)
            currentGroupNames = cell(self.desktop.getGroupTitles);
            if ~any(strcmp(name, currentGroupNames))
                ghandle = self.desktop.addGroup(name);
            else
                ghandle = [];
            end
        end
        
        % Setup Group Window
        function groupWindowSetup(self, dims, docked, mode)
            self.dims = dims;
            self.j_dims = java.awt.Dimension(dims(2), dims(1));
            self.docked = docked;
            self.mode = mode;
            
            % Docked or Windowed
            self.desktop.setGroupDocked(self.name, docked);
            self.desktop.setDocumentArrangement(self.name, mode, self.j_dims)
        end
        
        function hContainer = emptyContainer(self)
            temp_f = figure('Visible', 'on', 'WindowStyle', 'docked');
            jframe = getJFrame(self, temp_f);
            set(jframe, 'GroupName', self.name);
            drawnow
            
            hContainer = self.desktop.getGroupContainer(self.name);
            close(temp_f);
            clear temp_f 
            
            self.tilepane = hContainer.getComponent(0);
            self.hContainer = hContainer;
            % Preserve the group name in the container's userdata, for future use by user
            try
                set(self.hContainer,'userdata',self.name);
            catch
                % There was no userdata ...  
            end
            if ~self.visible
                self.hContainer.getTopLevelAncestor.hide;
            end
        end
        
        function hContainer = populatedContainer(self, figs)
            
            for i = 1:length(figs)
                figs(i).WindowStyle = 'docked';
            end
            addFigures(self, figs);
            f1_vis = figs(1).Visible;
            figs(1).Visible = 'on';
            drawnow
            
            hContainer = self.desktop.getGroupContainer(self.name);
            figs(1).Visible = f1_vis;
            
            self.tilepane = hContainer.getComponent(0);
            self.hContainer = hContainer;
            % Preserve the group name in the container's userdata, for future use by user
            try
                set(self.hContainer,'userdata',self.name);
            catch
                % There was no userdata ...  
            end
        end
        
        function hContainer = positionedContainer(self, figs, positions, merge)
            if nargin < 4
                merge = false;
            end
            for i = 1:length(figs)
                figs(i).WindowStyle = 'docked';
            end
            addPositionedFigures(self, figs, positions, merge);
            hContainer = self.hContainer;
        end
        
        % add Figures
        function addFigures(self, figs, positions)   
            if nargin == 3
                addPositionedFigures(self, figs, positions);
            else
                for i = 1:length(figs)
                    % Set the figure in the group 
                    jframe = getJFrame(self, figs(i));
                    set(jframe, 'GroupName', self.name);
                end
                drawnow;
            end
        end
        
        function addPositionedFigures(self, figs, positions, merge)
            
            i_size = size(positions);
            
            % Error Check
            if length(figs) ~= i_size(1)
                error('Dimesion missmatch between figs and positions');
            end
            
            % Add Temporary figures if needed
            temp_figs = tempFigures(self);
            
            % Itterate over all figures
            for i = 1:length(figs)
                % Get the correct index
                if i_size(2) == 2
                    index = (positions(i,1)-1)*self.dims(2) + positions(i,2);
                else
                    index = positions(i);
                end
                
                % Select the correct pane
                if (self.tilepane.getSelectedTile ~= (index-1))
                    self.tilepane.setSelectedTile(index-1);
                end
                
                % Set the figure in the group
                jframe = getJFrame(self, figs(i));
                set(jframe, 'GroupName', self.name);
                figs(i).Visible = 'on';
                drawnow;
            end
            self.hContainer.getTopLevelAncestor.show;
            
            % Remove Temporary Figures
            if nargin > 3 && merge
                pause(0.1);
            else
                pause(0.25);
            end
            close(temp_figs);
            clear temp_figs
        end
        
        function temp_figs = tempFigures(self)
            if isempty(self.tilepane)
                temp_figs = figure('Visible', 'on', 'WindowStyle', 'docked');
                jframe = getJFrame(self, temp_figs(end));
                set(jframe, 'GroupName', self.name);
                for i = 2:(self.dims(1)*self.dims(2)) 
                    temp_figs(end+1) = figure('Visible', 'on', 'WindowStyle', 'docked');
                    jframe = getJFrame(self, temp_figs(end));
                    set(jframe, 'GroupName', self.name);
                end
                drawnow;

                hContainer = self.desktop.getGroupContainer(self.name);

                self.tilepane = hContainer.getComponent(0);
                self.hContainer = hContainer;
                % Preserve the group name in the container's userdata, for future use by user
                try
                    set(self.hContainer,'userdata',self.name);
                catch
                    % There was no userdata ...  
                end
                self.hContainer.getTopLevelAncestor.hide;
            else
                temp_figs = figure('Visible', 'off', 'WindowStyle', 'docked');
                for i = 1:self.tilepane.getTileCount
                    if isempty(javaMethodEDT('getComponentInTile',self.tilepane,(i-1)))
                        temp_figs(end+1) = figure('Visible', 'on', 'WindowStyle', 'docked');
                        if (self.tilepane.getSelectedTile ~= (i-1))
                            self.tilepane.setSelectedTile(i-1);
                        end
                        jframe = getJFrame(self, temp_figs(end));
                        set(jframe, 'GroupName', self.name);
                    end
                end
                self.hContainer.getTopLevelAncestor.show;
                drawnow;
            end
        end
        
        function visiblity(self, visible)
            
            if visible
                if isempty(self.hContainer)
                    if all(ishghandle(self.figs)) && isempty(self.indices)
                        populatedContainer(self, self.figs);
                    else
                        positionedContainer(self, self.figs, self.indices, self.merge);
                    end
                else
                    self.hContainer.getTopLevelAncestor.show;
                end
            else
                if ~isempty(self.hContainer)
                    self.hContainer.getTopLevelAncestor.hide;
                end
            end
            
            
            self.visible = visible;
        end
        
        function [figs, indices] = parseCell(self, array)
            if ~iscell(array)
                error('Input must be a cell array')
            end
            [m, n] = size(array);
            figs = [];
            indices = [];
            for i = 1:m
                for j = 1:n
                    if ishghandle(array{i,j})
                        if isempty(figs)
                            figs = array{i,j};
                        else
                            figs(end+1) = array{i,j};
                        end
                        indices(end+1,:) = [i, j];
                    elseif iscell(array{i,j})
                        for k = 1:length(array{i,j})
                            if isempty(figs)
                                figs = array{i,j}{k};
                            else
                                figs(end+1) = array{i,j}{k};
                            end
                            indices(end+1,:) = [i, j];
                        end
                    end
                end
            end
            self.figs = figs;
            self.indices = indices;
        end
         
        function handleErrorMessage(self)
            v = version;
            if v(1)<='6'
                err.message = lasterr;  %#ok<LERR> % no lasterror function...
            else
                err = lasterror; %#ok<LERR>
            end
            try
                err.message = regexprep(err.message,'Error using ==> [^\n]+\n','');
            catch
                try
                    % Another approach, used in Matlab 6 (where regexprep is unavailable)
                    startIdx = strfind(err.message,'Error using ==> ');
                    stopIdx = strfind(err.message,char(10));
                    for idx = length(startIdx) : -1 : 1
                        idx2 = min(find(stopIdx > startIdx(idx)));  %#ok ML6
                        err.message(startIdx(idx):stopIdx(idx2)) = [];
                    end
                catch
                  % never mind...
                end
            end
            if isempty(strfind(err.message,mfilename))
                % Indicate error origin, if not already stated within the error message
                err.message = [mfilename ': ' err.message];
            end
            if v(1)<='6'
                while err.message(end)==char(10)
                    err.message(end) = [];  % strip excessive Matlab 6 newlines
                end
                error(err.message);
            else
                rethrow(err);
            end    
        end
    end    
end

