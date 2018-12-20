classdef TDTudp < handle
% TDTudp
%   Properties   
%   Connection Properties
%   :UDP:                   (object)    The udp object communicating with
%                                       the RZ unit.
%   :TDT_UDP_HOSTNAME:      (char)      The HOSTNAME of the RZ2 unit.
%   :UDP_PORT:              (double)    The PORT to use for the connection.
%   :Npackets:              (double)    The number of words in the UDP
%                                       packet.
%   :UDP_HEADER_PREFACE:    (char)      The mandatory first part of the
%                                       UDP packet header.
%   :UDP_header:            (double)    The header of the UDP packet        
%    
%   UDP Command Constants
%   :CMD_SEND_DATA:         (char)      The header command for sending data.
%   :CMD_GET_VERSION:       (char)      The header command for getting the 
%                                       version.
%   :CMD_SET_REMOTE_IP:     (char)      The header command for setting the IP.
%   :CMD_FORGET_REMOTE_IP:  (char)      The header command for removing the IP.
    properties
        % Object %
        TOOLBOX = false
        VERBOSE = false
        
        % Connection Properties %
        SOCKET
        HOSTNAME           = '10.1.0.100'
        PORT               = 22022
        INPUT_BUFFER_SIZE  = 4096
        OUTPUT_BUFFER_SIZE = 4096
        
        % Data Packet %
        TYPE           = 'int32'
        HEADER_PREFACE = '55AA'
        HEADER         = []
        SORTS          = 0
        BITS           = 0
        REORDER        = []
        
        % UDP Command Constants %
        CMD_SEND_DATA        = '00'
        CMD_GET_VERSION      = '01'
        CMD_SET_REMOTE_IP    = '02'
        CMD_FORGET_REMOTE_IP = '03'
    end
    
    methods
        function self = TDTudp(varargin)
            % parse varargin
            for i = 1:2:length(varargin)
                eval(['obj.' upper(varargin{i}) '=varargin{i+1};']);
            end
            
            box = ver;
            for i = 1:numel(box)
                if strcmp(box(i).Name, 'Instrument Control Toolbox')
                    self.TOOLBOX = true;
                end
            end
            
            self.REORDER = zeros(1,32);
            ind = 1;
            for j = 32:-self.BITS:1
                self.REORDER(ind:ind+self.BITS-1) = j-self.BITS+1:j;
                ind = ind + self.BITS;
            end
            self.open();
        end
        
        function delete(self)
            self.disconnect();
            if self.TOOLBOX
                delete(self.SOCKET);
            else
                %delete(self.SOCKET);
            end
        end
        
        function buildSocket(self)
            try
                if self.TOOLBOX
                    self.SOCKET = udp(self.HOSTNAME, self.PORT, ...
                        'InputBufferSize', self.INPUT_BUFFER_SIZE, ...
                        'OutputBufferSize', self.OUTPUT_BUFFER_SIZE);
                else
                    self.SOCKET = pnet('udpsocket', self.PORT);
                    pnet(self.SOCKET, 'setwritetimeout', 1);
                    pnet(self.SOCKET, 'setreadtimeout', 1);
                end
            catch
                error('problem creating UDP socket')
            end
        end
        
        function connect(self)
            if self.TOOLBOX
                fopen(self.SOCKET);
                if ~strcmp(get(self.SOCKET, 'Status'), 'open')
                    error('problem opening UDP socket')
                end
            else
                pnet(self.SOCKET, 'udpconnect', 'HOSTNAME', self.HOSTNAME);
            end
        end
        
        function disconnect(self)
            if ~isempty(self.SOCKET)
                if self.TOOLBOX
                    fclose(self.SOCKET);
                else
                    %fclose(self.SOCKET);
                end
            end
        end
        
        function open(self)
            self.buildSocket();
            self.connect();
        end
        
        function header = buildHeader(self, command, n_packets)
            header = hex2dec([self.HEADER_PREFACE, command, dec2hex(n_packets, 2)]);
            self.HEADER = header;
        end
        
        function [chans, e] = readHeader(self, input)
            header = TYPEcast(single(input), 'uint32');
            if bitshift(header, -16) == hex2dec(self.HEADER_PREFACE)
                chans = bitand(header, 2^16-1);
                if self.VERBOSE
                    disp(['number of channels ' num2str(num_chan)])
                end
                e = 1;
            else
                chans = 0;
                e = 0;
            end
        end
        
        function sendIP(self)
            packet = hex2dec([self.HEADER_PREFACE, self.CMD_SET_REMOTE_IP, '00']);
            if self.TOOLBOX
                fwrite(self.SOCKET, packet, 'int32');
            else
                pnet(self.SOCKET, 'write', int32(packet));
                pnet(self.SOCKET, 'writepacket', self.HOSTNAME, self.PORT);
            end
        end
        
        function sendDatagram(self, datagram)
            if isa(datagram, 'double')
                datagram = single(datagram);
            end
            datagram = typecast(datagram, 'int32');
            header = buildHeader(self, self.CMD_SEND_DATA, numel(datagram));
            packet = [header, datagram];
            if self.TOOLBOX
                fwrite(self.SOCKET, packet, 'int32');
            else
                pnet(self.SOCKET, 'write', int32(packet));
                pnet(self.SOCKET, 'writepacket', self.HOSTNAME, self.PORT);
            end
        end
        
        function packet = read(self)
            % read a single packet in as uint32
            if self.TOOLBOX
                packet = fread(self.SOCKET, 1, 'uint32');
            else
                % read a single packet in
                len = pnet(self.SOCKET, 'readpacket');
                if len > 0
                    % if packet larger then 1 byte then read maximum of 1000 doubles in network byte order
                    packet = pnet(self.SOCKET, 'read', self.input_buffer_size, 'uint32', 'network')';
                end
            end
        end
        
        function data = packet2data(self, data)
            if self.SORTS == 0 || self.BITS == 0
                data = typecast(data, self.TYPE);
            else
                % pack it all into one binary string
                bstr = reshape(dec2bin(data, 32)',1,[]);
                
                % put it in order.  read each 32-bit chunk backwards, by
                % bit count
                for i = 1:32:numel(bstr)
                    t = bstr(i:i+31);
                    bstr(i:i+31) = t(self.REORDER);
                end
                
                % now pull it apart
                s = [];
                sort_ind = 1e10;
                chan_ind = 0;
                
                for i = 1:self.BITS:numel(bstr)
                    if sort_ind > self.SORTS
                        sort_ind = 1;
                        chan_ind = chan_ind + 1;
                        %chan_field = ['ch' num2str(chan_ind)];
                        %s.(chan_field) = [];
                    end
                    v = bin2dec(bstr(i:self.BITS+i-1));
                    %s.(chan_field)(sort_ind) = v;
                    s(chan_ind,sort_ind) = v;
                    
                    sort_ind = sort_ind + 1;
                end
                data = s;

            end
        end
        
        function [data, chans] = readPacket(self, packet)
            data = [];
            [chans, e] = self.readHeader(packet);
            if e
                data = self.packet2data(packet(2:end));
            end
        end
        
        function [data, chans] = readPackets(self, packets)
            data = {};
            for p = 1:length(packets)
                [data{p}, chans(p)] = self.readPacket(packets{p});
            end
        end
        
        function [packet, e] = receivePacket(self, timeout)
            packet = [];
            e = 0;
            start = clock;
            while timeout > etime(start, clock)
                packet = self.read();
                if ~isempty(packet)
                    [~, e] = self.readHeader(packet);
                    if e, break; end
                end
            end
        end
        
        function [packets, e] = receiveStream(self, timeout)
            packets = {};
            while true
                [packet, e] = self.receivePacket(timeout);
                if ~isempty(packet) && e
                    packets{end+1} = packet;
                else
                    e = 0;
                    break
                end
            end
        end
    end
    
end

