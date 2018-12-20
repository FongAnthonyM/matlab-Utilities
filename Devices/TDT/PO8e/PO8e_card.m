classdef PO8e_card < basePO8e
    
    properties
        card_count
        previous_samples
        MAX_SAMPLES = 10000
    end
    
    methods
        function self = PO8e_card()
            self@basePO8e();
            self.cardCount();
        end
        
        function delete(self)
            self.release();
        end
        
        function card_count = cardCount(self, verb)
            card_count = calllib(self.LibName, 'cardCount');
            if nargin > 2 && verb
                fprintf('Found %d card(s) in the system.\n', card_count);
            end
            self.card_count = card_count;
        end
        
        function connect(self, verb)
            if nargin < 2
                verb = false;
            end
            
            cardCount(self);
            if self.card_count == 0
                warning('No cards found. No connections.')
            else
                for i = 1:self.card_count
                    if verb, fprintf('Connecting to Card %d...\n', i); end
                    self.connectToCard(i);
                    pause(0.1)
                    if (self.isNull(i))
                        warning('Card %d: Connection Failed.\n', i);
                    else
                        if verb, fprintf('Card %d: Connection Established.\n', i); end
                    end
                end
            end
        end
        
        function release(self, cards, verb)
            if nargin < 2
                cards = 1:self.card_count;
            end
            
            for i = cards
                if ~isempty(self.CardPointer{i})
                    self.releaseCard(i);
                    if nargin > 2 && verb, fprintf('Card %d: Released\n', i); end
                end
            end
        end
        
        function startCollection(self, verb)
            if nargin < 2
                verb = false;
            end
            
            count = self.cardCount();
            if (0 == count)
                error('Cannot start collection, no cards found.\n');
            end
            
            if verb, disp('Connecting to PO8e...'); end
            connect(self, verb);
            for i = 1:count
                if ~self.startCollecting(i, 1)
                    err = self.getLastError(i);
                    self.releaseCard(i);
                    warning('startCollection() failed with: %d\n', err);
                    error('startCollection() failed with: %d\n', err);
                else
                    [n_samples, ~] = self.samplesReady(i);
                    if n_samples > 0
                        self.flushBufferedData(i, -1, 0);
                    end
                    if verb, fprintf('Successfully Connected to Card %d.\n', i); end
                end
            end
            
            ready = false;
            if verb, disp('Waiting for data...'); end
            while ~ready
                for i = 1:self.card_count
                    [n_samples, ~] = self.samplesReady(i);
                    if n_samples > 0
                        self.readBlock(i, n_samples);
                        if (self.Status(i) == 0)
                            warning('Reading block failed; no samples returned');
                        else
                            self.flushBufferedData(i, n_samples, 0);
                            no = min(min(self.Offsets{i}));
                            disp(no)
                            if no > 256
                                ready = true;
                                if verb, disp('Data received. PO8e is collecting incoming data.'); end
                            end
                        end
                    end
                end
                pause(0.025)
            end
            
            self.clearBuffer();
        end
        
        function n_samples = collectData(self, cards, verb)
            if nargin < 2
                cards = 1:self.card_count;
            end
            
            if nargin < 3
                verb = false;
            end
            
            n_samples = [];
            for i = cards
                [n_samples(i), ~] = self.samplesReady(i);
                if n_samples(i) > 0
                    self.readBlock(i, n_samples(i));
                    if (self.Status(i) == 0)
                        warning('Card %d: Reading block failed; no samples returned', i);
                    else
                        self.flushBufferedData(i, n_samples(i), 0);
                        size(self.Data{i});
                        xd = max(max(self.Data{i}));
                        nd = min(min(self.Data{i}));
                        xo = max(max(self.Offsets{i}));
                        no = min(min(self.Offsets{i}));
                        if verb, fprintf('Card %d: n_samples = %d, %.10f %.10f %d %d\n', i, n_samples(i), nd, xd, no, xo); end
                    end
                end
            end
            self.previous_samples = n_samples;
        end
        
        function [data, n_samples] = returnData(self, cards)
            if nargin < 1
                cards = 1:self.card_count;
            end
            n_samples = self.collectData(cards);
            
            data = {};
            for card = cards
                data{card} = self.Data{card};
            end
        end
        
        function [data, n_samples] = returnChannels(self, card, IDs)
            n_samples = self.previous_samples(card);
            data = double(self.Data{card}(IDs, 1:n_samples));
        end
        
        % data overwritten
        function [r_samples, stopped] = readData(self, card, n_samples, verb)
            if nargin < 4
                verb = false;
            end
            
            if self.isStopped(card)
                stopped = 1;
            elseif n_samples > 0
                stopped = 0;
                r_samples = min(n_samples, self.MAX_SAMPLES);
                self.readBlock(card, r_samples);
                if (self.Status(card) == 0)
                    warning('Card %d: Reading block failed; no samples returned', card);
                else
                    self.flushBufferedData(card, r_samples, 0);
                    size(self.Data{card});
                    xd = max(max(self.Data{card}));
                    nd = min(min(self.Data{card}));
                    xo = max(max(self.Offsets{card}));
                    no = min(min(self.Offsets{card}));
                    if verb, fprintf('Card %d: n_samples = %d, %.10f %.10f %d %d\n', card, r_samples, nd, xd, no, xo); end
                end
            end
        end
        
        function clearBuffer(self)
            while true
                for i = 1:self.card_count
                    [samples(i), ~] = self.samplesReady(i);
                end
                
                n_samples = samples;
                for i = 1:self.card_count
                    while n_samples(i) > 0
                        [r_samples, stopped] = readData(self, i, n_samples(i));
                        n_samples(i) = n_samples(i) - r_samples;
                        if stopped, break; end
                    end
                end
                
                disp(samples(1))
                if all(samples < 100)
                    disp(samples(1))
                    break
                end
                pause(0.01)
            end
        end
    end
    
end

