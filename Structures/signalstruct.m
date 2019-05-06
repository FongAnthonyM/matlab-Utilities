classdef signalstruct < matlab.mixin.SetGet
% signalstruct
%   A handles (Set & Get type) subclass that holds data for a signal.
%   :self:		handle		A handle that points to the signal object
%   :name:		string		The name of the channel
%   :ID:		double		The ID of that channel
%   :type:		cell array	Contains type name and number of that type
%   :data:		matrix		Data
%   :data_set:	cell array	Multiple data sets
    
properties
    Info
    nDims
    indicies
    NaNindicies
    
    data
    data_set = {}
end

properties (Access = private)
    pIndicies
    pSize
    pNaNindicies
    pNaNsize
end

methods
    %% ---- Methods ---- %%
    function self = signalstruct(name, ID, type, data)
    % signalstruct
    %   Creates and builds a signalstruct object
    %   Inputs
    %   :name:		string		The name of the channel
    %   :ID:		double		The ID of that channel
    %   :type:		cell array	Contains type name and number of that type
    %   :data:		matrix		Data to store
    %   Outputs
    %   :self:		handle      A handle that points to the signal object
        if nargin >= 3
            self.Info.Name = name;
            self.Info.ID   = ID;
            self.Info.Type = type;
            if nargin > 3 
                self.data  = data;
            end
        end
    end
    
    function nd = get.nDims(self)
        sz = size(self.data);
        nd = ndims(self.data);
        if sz(nd) == 1
            nd = nd - 1;
        end
    end
    
    function index = get.indicies(self)
        s = self.size();
        if isempty(self.pSize) || size(self.pSize,2) ~= size(s,2) || any(self.pSize ~= s)
            index = {};
            for d = 1:length(s)
                v = 1:s(d) ;
                if ~isempty(v)
                    index{d} = v;
                end
            end
            self.pSize = s;
            self.pIndicies = index;
        else
            index = self.pIndicies;
        end
    end
    
    function index = get.NaNindicies(self)
        s = self.NaNsize();
        if isempty(self.pNaNsize) || size(self.pNaNsize,2) ~= size(s,2) || any(self.pNaNsize ~= s)
            index = {};
            for d = 1:length(s)
                v = 1:s(d) ;
                if ~isempty(v)
                    index{d} = v;
                end
            end
            self.pNaNsize = s;
            self.pNaNindicies = index;
        else
            index = self.pNaNindicies;
        end
    end
    
    function setData(self, data)
        self.data = data;
        self.indicies;
    end
    
    function addData(self, d, s)
        index = self.indexParse(s);
        self.data(index{:}) = d;
    end
    
    function appendData(self, data, dim)
        d_size = size(data);
        index = self.indicies;
        if isempty(index) || dim > size(index,2)+1
            for i = 1:length(d_size)
                index{i} = 1:d_size(i);
            end
            index{dim} = (1:size(data, dim));
        elseif dim == size(index,2)+1
            index{dim} = (2:size(data, dim)+1);
        elseif dim <= size(index,2)
            index{dim} = index{dim}(end)+(1:size(data, dim));
        end
        self.data(index{:}) = data;
    end
    
    function appendDataNaN(self, data, dim)
        index = self.NaNindicies;
        if isempty(index) || dim > size(index,2)+1
            index{dim} = (1:size(data,dim));
        elseif dim == size(index,2)+1
            index{dim} = (2:size(data, dim)+1);
        elseif dim <= size(index,2)
            index{dim} = index{dim}(end)+(1:size(data, dim));
        end
        self.data(index{:}) = data;
    end
    
    function d = getData(self, s)
        index = self.indexParse(s);
        d = self.data(index{:});
    end
    
    function clearData(self, data, d_s)
    % clearData
    %   Clears data in Data and Data_set or relpaces it 
    %   Inputs
    %   :self:      handle      A handle that points to the signal object
    %   :data:		matrix		Optional data to relpace data
        if nargin == 2
            self.data = data;
            self.data_set = {};
        elseif nargin == 3
            self.data = data;
            self.data_set = d_s;
        else
            self.data = [];
            self.data_set = {};
        end
    end
    
    function retainData(self, start, stop)
        t_d = self.data(start, stop);
        self.clearData(t_d);
    end
    
    function retainReplace(self, d, start, stop)
        t_d = self.data(start, stop);
        self.clearData(d);
        self.data(1:length(t_d)) = t_d;
    end
    
    function index = indexParse(self, s)
        if ~iscell(s)
            s = {s};
        end
        index = self.indicies;
        for d = 1:length(s)
            d_i = s{d};
            if ~isempty(d_i)
                index{d} = d_i;
            end
        end
    end
    
    function s = size(self, d)
        if nargin == 2 && ~isempty(d)
            s = size(self.data, d);
        else
            s = size(self.data);
        end
    end
    
    function s = NaNsize(self)
        s = zeros(1, self.nDims);
        logi = ~isnan(self.data);
        for d = 1:self.nDims
            len = find(logi,d,'last');
            if ~isempty(len)
                s(d) = len;
            else
                s(d) = 0;
            end
        end
    end
    
    function s = arraysize(self)
        s = size(self.data_set);
    end
    
    function new = copy(self)
    % copy
    %   Creates a new singalstuct object with same data as this object
    %   Inputs
    %   :self:      handle      A handle that points to the signal object
    %   Outputs
    %   :new:       handle      New signalstruct object with the same data
        new = signalstruct(self.name, self.ID, self.type, self.data);
        new.data_set = self.data_set;
    end
end
end

