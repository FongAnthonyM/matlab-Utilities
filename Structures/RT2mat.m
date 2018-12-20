function [ new_fmt ] = RT2mat( files, rm_list )
% RT2mat
%   Takes the output of the real-time platform and converts it into a
%   readable format
%   Parameters
%   :files:     cell array/struct   Can be an ordered array of strings of 
%                                   files to load and convert or an ordered
%                                   structure of all files made during the trial
%   :rm_list:   cell array          An array of strings of fields to remove
%                                   from the timestamps
%   Output
%   :new_fmt:   struct              All the data from the trail in a readable
%                                   format
    % ---- Setup ---- %
    % Either Load a list of files or set the structure with all the files
    if isa(files, 'cell')
        for index = 1:length(files)
            all_struct(index) = load(char(files(index)));
        end
    elseif isa(files, 'char')
        all_struct = load(files);
    else
        all_struct = files;
    end
    
    % Stitch together all files into one trial
    if length(files) > 1
        trial = stitcher(all_struct);
    else
        trial = all_struct;
    end
    
    % Make a list of fields to remove from the timestamps
    if nargin == 1
        rm_list = {'b_adj_sn', 'e_adj_sn'};
    end
    
    % ---- Conversion ---- %
    % General Information
    new_fmt.start = trial.all_timestamps.record_data.beginning;
    new_fmt.alginment_sample = trial.all_timestamps.record_data.zero;
    new_fmt.arguments = trial.args;
    
    % Timestamps
    ts_names = fieldnames(trial.all_timestamps);
    for index = 1:length(ts_names)
        ts_name = char(ts_names(index));
        ts = trial.all_timestamps.(ts_name).stamps;
        if isstruct(ts)
            flds = {};
            parts = fieldnames(ts.list);
            for j = 1:length(parts)
                for k = 1:length(rm_list)
                    if strcmp(parts(j), rm_list(k))
                        flds{end+1} = char(rm_list(k));
                    end
                end
            end
            new_fmt.(['ts_' ts_name]) = rmfield(ts.list, flds);
        end
    end
    
    % Channel Types
    new_fmt.channel_names = trial.ECoG.names;
    new_fmt.channel_types = trial.ECoG.types;
    new_fmt.channel_IDs = trial.ECoG.IDs;
    
    % Raw Data
    raw_data = [];
    for index = 1:trial.ECoG.total_recording
        raw_data(index,:) =  trial.ECoG.recording_channels(index).channel.data;
    end
    new_fmt.raw_data = raw_data;
    
    % Processed Signals
    pt_names = fieldnames(trial.ECoG.processed_signals);
    for index = 1:length(pt_names)
        p_type = trial.ECoG.processed_signals.(char(pt_names(index)));
        p_names = fieldnames(p_type);
        for j = 1:length(p_names)
            if isempty(p_type.(char(p_names(j))).data_set)
                new_fmt.(char(p_names(j))) = p_type.(char(p_names(j))).data;
            else
                new_fmt.(char(p_names(j))) = p_type.(char(p_names(j))).data_set;
            end
        end
    end
    
    % Save File
    disp('Saving File')
    path = [pwd '\'];
    ID = trial.args.patient_ID;
    name = trial.args.trial_name;
    date = datestr(new_fmt.start,'dd-mmm-yyyy_T-HH-MM-SS');
    save_fname = [path ID '_' name '_' date '_full.mat'];
    save(save_fname, '-struct', 'new_fmt', '-v7.3');
    
end

