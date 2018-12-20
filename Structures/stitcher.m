function [ whole ] = stitcher( all_struct )
% stitcher
%   Stitches the real-time ECoG data from multiple save files into one
%   Input
%   :all_struct:    struct    A multi struct with an ordered list of saved information
%   Output
%   :whole:         struct    A single struct with all infromation in one object 
    %% ---- Setup the Main Struct with the First Data ---- %%
    % ---- Timestamps ---- %
    ts_names = fieldnames(all_struct(1).all_timestamps);
    for index = 1:length(ts_names)
        ts_set = all_struct(1).all_timestamps.(char(ts_names(index)));
        all_timestamps.(char(ts_names(index))) = handle2Struct(ts_set);
    end
    
    % ---- ECoG ---- %
    ECoG = handle2Struct(all_struct(1).ECoG);
    % Channels %
    for index = 1:length(ECoG.channels)
        ECoG.channels(index) = copy(ECoG.channels(index));
    end
    % Recorded Channels % 
    for index = 1:length(ECoG.recording_channels)
        gen_index = ECoG.recording_channels(index).index;
        ECoG.recording_channels(index).channel = ECoG.channels(gen_index);
    end
    % Processed Signals %
    processed = fieldnames(ECoG.processed_signals);
    for index = 1:length(processed)
        pro = ECoG.processed_signals.(char(processed(index)));
        sigs = fieldnames(pro);
        for s_index = 1:length(sigs)
            pro.(char(sigs(s_index))) = copy(pro.(char(sigs(s_index))));
        end
    end
    % Control Singal %
    if isa(ECoG.control_signal, 'signalstruct')
        ECoG.control_signal = copy(ECoG.control_signal);
    end
    
    %% ---- Append Data from Other Structs ---- %%
    for index = 2:length(all_struct)
        % ---- Timestamps ---- %
        ts_names = fieldnames(all_struct(index).all_timestamps);
        for ts_index = 1:length(ts_names)
            ap_ts = all_struct(index).all_timestamps.(char(ts_names(ts_index)));
            ts_fields = fieldnames(ap_ts);
            for j = 1:length(ts_fields)
                ts_field = char(ts_fields(j));
                if ~strcmp(ts_field, 'stamps') && ~strcmp(ts_field, 'self')
                    all_timestamps.(char(ts_names(ts_index))).(ts_field) = ap_ts.(ts_field);
                end
            end
            
            if isstruct(ap_ts.stamps)
                total = length(ap_ts.stamps.list);
                if total > 1
                    temp = ap_ts.stamps.list(2:total);
                    all_timestamps.(char(ts_names(ts_index))).stamps.list(end+1:end+length(temp)) = temp;
                end
            end
        end
        % ---- ECoG ---- %
        % Channels %
        first = all_struct(index).all_timestamps.record_data.stamps.list(2).b_sample_number;
        last = all_struct(index).all_timestamps.record_data.stamps.list(end).e_sample_number;
        b_adjust = all_struct(index).all_timestamps.record_data.stamps.list(2).b_adj_sn;
        e_adjust = all_struct(index).all_timestamps.record_data.stamps.list(end).e_adj_sn;
        for c_index = 1:length(all_struct(index).ECoG.recording_channels)
            appendData(ECoG.recording_channels(c_index).channel, all_struct(index).ECoG.recording_channels(c_index).channel, first, last, b_adjust, e_adjust);
        end
        % Processed Singals %
        processed = fieldnames(all_struct(index).ECoG.processed_signals);
        for p_index = 1:length(processed)
            n_pro = all_struct(index).ECoG.processed_signals.(char(processed(p_index)));
            o_pro = ECoG.processed_signals.(char(processed(p_index)));
            sigs = fieldnames(n_pro);
            for s_index = 1:length(sigs)
                old = size(o_pro.(char(sigs(s_index))).data);
                new = size(n_pro.(char(sigs(s_index))).data);
                old_last = old(end)+1;
                next_last = new(end);
                appendDataEnd(o_pro.(char(sigs(s_index))), n_pro.(char(sigs(s_index))), old_last, next_last, old_last, next_last);
            end
        end
        % Control Singal %
        if isa(ECoG.control_signal, 'signalstruct')
            b_new = 1;
            e_new = length(all_struct(index).ECoG.control_signal.data);
            b_old = length(ECoG.control_signal.data)+1;
            e_old = length(ECoG.control_signal.data)+e_new;
            appendData(ECoG.control_signal, all_struct(index).ECoG.control_signal, b_old, e_old, b_new, e_new);
        end
    end
    
    whole.args = all_struct(1).args;
    whole.all_timestamps = all_timestamps;
    whole.ECoG = ECoG;
    whole.info_log = all_struct(end).log;
end

 function result = handle2Struct(handle)
 % handle2Struct
 %   Create a copy of a handle as a struct
 %   Input
 %   :handle:    handle    The handle to transform into a struct
 %   Output
 %   :result:    struct    The struct copy of the handle  
    contents = fieldnames(handle);
    for index = 1:length(contents)
        result.(char(contents(index))) = handle.(char(contents(index)));
    end
 end

 function appendData(orig_signal, new_signal, first, last, b_adjust, e_adjust)
 % appendData
 %   Appends data from one signalStruct to another
 %   Input
 %   :orig_signal:  signalStruct    The singal to append the data to
 %   :new_signal:   signalStruct    The new singal which will be added to the original
 %   :first:        double          The first index that the start of the new singal will be appended to
 %   :last:         double          The last index that the end of the new signal will be appended to
 %   :b_adjust:     double          The first index of the new data to be added from the new signal
 %   :e_adjust:     double          The last index of the new data to be added from the new signal
    if ~isempty(length(new_signal.data))
        temp_data = new_signal.data(b_adjust:e_adjust);
        orig_signal.data(first:last) = temp_data;
    end
    if ~isempty(new_signal.data_set)
        orig_signal.data_set = [orig_signal.data_set, new_signal.data_set];
    end
 end
 
 function appendDataEnd(orig_signal, new_signal, first, last, b_adjust, e_adjust)
    
    siz = size(new_signal.data);
    if ~isempty(length(new_signal.data))
        if 6==length(size(new_signal.data))
            temp_data = new_signal.data(:,:,:,:,:,b_adjust:e_adjust);
            orig_signal.data(:,:,:,:,:,first:last) = temp_data;
        elseif 5==length(size(new_signal.data))
            temp_data = new_signal.data(:,:,:,:,b_adjust:e_adjust);
            orig_signal.data(:,:,:,:,first:last) = temp_data;
        elseif 4==length(size(new_signal.data))
            temp_data = new_signal.data(:,:,:,b_adjust:e_adjust);
            orig_signal.data(:,:,:,first:last) = temp_data;
        elseif 3==length(size(new_signal.data))
            temp_data = new_signal.data(:,:,b_adjust:e_adjust);
            orig_signal.data(:,:,first:last) = temp_data;
        elseif 2==length(size(new_signal.data)) && ~(siz(1)==1)
            temp_data = new_signal.data(:,b_adjust:e_adjust);
            orig_signal.data(:,first:last) = temp_data;
        else
            temp_data = new_signal.data(b_adjust:e_adjust);
            orig_signal.data(first:last) = temp_data;
        end
    end
    
    
    
    
    if ~isempty(new_signal.data_set)
        orig_signal.data_set = [orig_signal.data_set, new_signal.data_set];
    end
 end
 