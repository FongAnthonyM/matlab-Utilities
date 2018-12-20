classdef infoLog < matlab.mixin.SetGet
% infoLog
%   A handles (Set & Get type) subclass that logs and displays information 
%   the programmer wants 
%   :self:      handle          Points to this infoLog object
%   :name:      string          The name of this infoLog object
%   :parent:    handle          Points to the parent of this object
%   :list:      cell_array      The text strings of the log
properties
    self
    name
    parent
    
    list = cell(1,0)
end

methods
    function self = infoLog(name, parent, strings)
    % infoLog
    %   Creates and builds an ECoGstruct Object
    %   Input
    %   :name:      string      The name of this infoLog object
    %   :parent:    handle  	Points to the parent of this object
    %   :stings:    cell array  Array of initial info to add
    %   Outputs
    %   :self:      handle      A handle that points to the infoLog object
        if nargin > 0
            self.name = name;
            self.self = self;
            if nargin > 1
                append(self, parent);
            elseif nargin > 2
                self.parent = parent;
                append(self, strings, true, true);
            end
        end
    end
    
    function index = append(self, items, show, parent)
    % append
    %   Appends either a string or a cell array of strings to the infoLog
    %   and prints it
    %   Inputs
    %   :self:      handle      A handle that points to the infoLog object
    %   :items:     cell array  All of the strings to add to the infoLog
    %   :show:      boolean     Print the info or not
    %   :parent:    bool/handle A boolean to display to self parent or  
    %                           handle to display to other
    %   Output
    %   :index:     int         The last index in the infoLog cell array
        % Set optional parameters %
        if nargin < 3
            show = true;
        end
        
        if nargin > 3
            out = true;
            if isa(parent, 'logical')
                out = parent;
                parent = self.parent;
            end
        else
            out = false;
        end
        
        % Check if the new item is a list or a single string %
        if ischar(items)
            strings = {items};
        else
            strings = items;
        end
        
        % Add new strings and display them if requested %
        for s = 1:length(strings)
            index = length(self.list)+1;
            self.list{index} = strings{s};
            if show
                % Display to command line
                disp(strings{s})
                % Display to parent
                if out
                    set(parent,'String', self.list);
                    set(parent,'Value', index);
                end
            end
        end
    end

end
    
end

