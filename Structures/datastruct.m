classdef datastruct < matlab.mixin.SetGet
    properties
        Info
        Length
        Last
        Types
        
        List
        Struct = struct;
    end
    
    properties (Access = private)
        pTypes = {};
    end
    
    methods
        function self = datastruct(channels)
            if nargin == 1
                addChannels(self, channels);
            end
        end
        
        function len = get.Length(self)
            len = length(self.List);
        end
        
        function last = get.Last(self)
            last = self.List(1).NaNsize();
        end
        
        function types = get.Types(self)
            for t = 1:length(self.pTypes)
                type = self.pTypes{t};
                types(t).Name = type;
                types(t).nChannels = length(self.Struct.(type));
            end
        end
        
        function addChannels(self, channels)
            [c, ~] = size(channels);
            
            for i = 1:c
                self.addInfo(channels(i,:));
                channel = signalstruct(channels{i,:});
                self.add2List(channel);
                self.add2Struct(channel);
            end
        end
        
        function addInfo(self, info)
            if isempty(self.Info)
                self.Info.Name = info{1}; 
                self.Info.ID   = info{2};
                self.Info.Type = info{3};
            else
                self.Info(end+1).Name = info{1}; 
                self.Info(end).ID   = info{2};
                self.Info(end).Type = info{3};
            end
        end
        
        function addTypes(self, type)
            self.pTypes = union(type,self.pTypes);
        end
        
        function add2List(self, channel)
            if isempty(self.List)
                self.List = channel;
            else
                self.List(end+1) = channel;
            end
        end
        
        function add2Struct(self, channel)
            type = channel.Info.Type;
            self.addTypes(type);
            if isfield(self.Struct, type)
                self.Struct.(type)(end+1) = channel;
            else
                self.Struct.(type) = channel;
            end
        end
        
        function c = findChannels(self, method, keys)
            switch method
                case 'index'
                    c = self.findIndex(keys);
                case 'name'
                    c = self.findname(keys);
                case 'id'
                    c = self.findID(keys);
                case 'type'
                    c = self.findTypes(keys);
                otherwise
                    error('Invalid Method');
            end
        end
        
        function c = findIndex(self, indices)
            c = self.List(indices);
        end
        
        function c = findName(self, names)
            [~, ind] = ismember(names, {full.List(:).name});
            c = self.List(ind(ind>0));
        end
        
        function c = findID(self, IDs)
            [~, ind] = ismember(IDs, {full.List(:).ID});
            c = self.List(ind(ind>0));
        end
        
        function c = findType(self, types)
            for t =1:length(types)
                type = types{t};
                c.(type) = self.Struct.(type);
            end
        end
        
        function addData(self, method, data, s)
            switch method
                case 'list'
                    self.addDataList(data, s);
                case 'type'
                    self.addDataType(data, s);
                otherwise
                    error('Invalid Method');
            end
        end
        
        function addDataList(self, data, s)
            for i = 1:self.Length
                self.List(i).addData(data{i}, s);
            end
        end
        
        function addDataType(self, data, s)
            fields = fieldnames(data);
            for t = 1:length(fields)
                type = fields{t};
                for c = 1:length(self.Struct.(type))
                    self.Struct.(type)(c).addData(data.(type){c}, s);
                end
            end
        end
        
        function addDataIndex(self, indicies, data, s)
            for i = 1:length(indicies)
                index = indicies(i);
                self.List(index).addData(data{i}, s);
            end
        end
        
        function appendDataList(self, data, d)
            if ~iscell(data)
                data = {data};
            end
            for i = 1:self.Length
                self.List(i).appendData(data{i}, d);
            end
        end
        
        function appendDataNaNList(self, data, d)
            if ~iscell(data)
                data = {data};
            end
            for i = 1:self.Length
                self.List(i).appendDataNaN(data{i}, d);
            end
        end
        
        function d = getData(self, method, keys, s)
            switch method
                case 'list'
                    d = self.getDataList(s);
                case 'type'
                    d = self.getDataTypes(keys, s);
                case 'index'
                    d = self.getDataIndex(keys, s);
                otherwise
                    error('Invalid Method');
            end
        end
        
        function d = getDataList(self, s)
            nd = self.List(1).nDims;
            d = cat(nd+1, self.List.data);
            if nargin > 1
                index = self.indexParse(s, size(d));
                d = d(index{:});
            end
        end
        
        function d = getDataTypes(self, types, s)
            if iscell(types)
                for t = 1:length(types)
                    type = types{t};
                    nd = self.Struct.(type)(1).nDims;
                    data = cat(nd+1, self.Struct.(type).data);
                    if nargin > 2
                        index = self.indexParse(s, size(data));
                        data = data(index{:});
                    end
                    d.(type) = data;
                end
            else
                nd = self.Struct.(types)(1).nDims;
                if nargin == 2
                    d = cat(nd+1, self.Struct.(types).data);
                else
                    d = cat(nd+1, self.Struct.(types).getData(s));
                end
            end
        end
        
        function d = getDataIndex(self, indicies, s)
            nd = self.List(1).data.nDims;
            d = cat(nd+1, self.List(indicies).data);
            if nargin > 2
                index = self.indexParse(s, size(d));
                d = d(index{:});
            end
        end
        
        function index = indexParse(~, in, s)
            if ~iscell(in)
                in = {in};
            end
            t = length(in);
            for d = 1:length(s)
                if d <= t
                    d_i = in{d};
                    if ~isempty(d_i)
                        index{d} = d_i;
                    else
                        index{d} = 1:s(d);
                    end
                else
                    index{d} = 1:s(d);
                end
            end
        end
    end
end

