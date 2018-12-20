classdef ECoGstruct < matlab.mixin.SetGet
% ECoGstruct
%   A handles (Set & Get type) subclass that holds datastructs
%   :Names:         cell array	Names of the datastructs
%   :Length:        double      The number of datastructs in this object
%   :Structures:    struct      A Struct of relevent datastructs
    
properties
    Names
    Length
    
    Structures
end

methods
    %% ---- Methods ---- %%
    function self = ECoGstruct(names, info)
    % ECoGstruct
    %   Creates and builds an ECoGstruct Object
    %   Input
    %   :names:     cell array	Names of data stuctures being added.
    %   :info:      cell array  Channel information the datastructs.
    %   Outputs
    %   :self:      handle      A handle that points to the ECoG object
        if nargin == 2
            self.createStructs(names, info);
        end
    end
    
    function d_struct = createStructs(self, names, info)
        if iscell(names)
            for n = 1:length(names) 
                ds = datastruct(info{n});
                self.Structures.(names{n}) = ds;
                d_Structures.(names{n}) = ds;
            end
        else
            d_struct = datastruct(info);
            self.Structures.(names) = d_struct;
        end
        self.Names = [self.Names {names}];
    end
    
    function r_struct = createRegions(self, names, info)
        if iscell(names)
            for n = 1:length(names) 
                ds = signalstruct(info{n}{:});
                self.Structures.(names{n}) = ds;
                r_Structures.(names{n}) = ds;
            end
        else
             r_struct = signalstruct(info{:});
            self.Structures.(names) = r_struct;
        end
        self.Names = [self.Names names];
    end
    
    function len = get.Length(self)
        len = length(self.Names);
    end
    
    function s = getStruct(self, name)
        s = self.Structures.(name);
    end
    
    function d = getData(self, method, name, keys, s)
        switch method
            case 'list'
                d = self.getDataList(name, start, s);
            case 'type'
                d = self.getDataTypes(name, keys, s);
            case 'index'
                d = self.getDataIndex(name, keys, s);
            otherwise
                error('Invalid Method');
        end
    end
    
    function d = getDataList(self, name, s)
        d = self.Structures.(name).getDataIndex(s);
    end
    
    function d = getDataType(self, name, types, s)
        d = self.Structures.(name).getDataTypes(types, s);
    end
    
    function d = getDataIndex(self, name, indicies, s)
        d = self.Structutes.(name).getDataIndex(indicies, s);
    end
end
    
end

