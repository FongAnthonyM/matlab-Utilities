function varargout = TDT_selectChannels(varargin)
% SELECTCHANNEL MATLAB code for selectChannel.fig
%      SELECTCHANNEL, by itself, creates a new SELECTCHANNEL or raises the existing
%      singleton*.
%
%      H = SELECTCHANNEL returns the handle to a new SELECTCHANNEL or the handle to
%      the existing singleton*.
%
%      SELECTCHANNEL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SELECTCHANNEL.M with the given input arguments.
%
%      SELECTCHANNEL('Property','Value',...) creates a new SELECTCHANNEL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TDT_selectChannels_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TDT_selectChannels_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help selectChannel

% Last Modified by GUIDE v2.5 16-May-2018 09:03:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TDT_selectChannels_OpeningFcn, ...
                   'gui_OutputFcn',  @TDT_selectChannels_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes during object creation, after setting all properties.
function channelName1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channelName1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function typeSelect1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to typeSelect1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function extraSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to extraSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

%%
% --- Executes just before selectChannel is made visible.
function TDT_selectChannels_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to selectChannel (see VARARGIN)

if nargin == 4 && ~isempty(varargin{1}) && isstruct(varargin{1}{1})
    names = varargin{1}{1}.names;
    wavs = varargin{1}{1}.wav_names;
    wvcs = varargin{1}{1}.chans;
    types = varargin{1}{1}.type_names;
    wav_values = varargin{1}{1}.w_values;
    t_values = varargin{1}{1}.t_values;
    record_i = varargin{1}{1}.record_i;
elseif nargin>=8
    names = varargin{1};
    wavs = varargin{2};
    wvcs = varargin{3};
    types = varargin{4};
    if isstruct(types)
        types = fieldnames(types);
    end
    record_i = varargin{5};
    wav_values = varargin{6};
    t_values = varargin{7};
else
    names = {'first','second'};
    wavs = {'Wav1','Wav2','Wav3','Wav4'};
    wvcs = [3 10];
    types = {'stim','return'};
    record_i = 1;
end

get_from = zeros(1,length(names));

for index = 1:length(record_i)
    get_from(record_i(index)) = 1;
end

if ~strcmp(wavs{length(wavs)},'None')
    wavs{length(wavs)+1} = 'None';
end
if ~strcmp(types{length(types)},'None')
    types{length(types)+1} = 'None';
end

if nargin > 3 && ~isempty(varargin{1}) && (isstruct(varargin{1}{1}) || nargin>=8)
    handles.channels = createChannels(handles.innerPanel, names, wavs, wvcs, types, get_from, wav_values, t_values);
else
    handles.channels = createChannels(handles.innerPanel, names, wavs, wvcs, types, get_from);
end
%handles.min_channels = length(names);
handles.min_channels = 1;
handles.wavs = wavs;
handles.types = types;
handles.allowed = false;
% Choose default command line output for selectChannel
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes selectChannel wait for user response (see UIRESUME)
uiwait(handles.selectChannel);
end

% --- Outputs from this function are returned to the command line.
function [varargout] = TDT_selectChannels_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
r_info   = {};
record_i = [];
for index = 1:length(handles.types)
    types.(handles.types{index}) = [];
end
for index = 1:length(handles.channels)
    name = get(handles.channels(index).text, 'String');
    w_values(index) = get(handles.channels(index).wav, 'Value');
    wav = handles.wavs{w_values(index)};
    wavs{index} = wav;
    wvcs(index) = str2double(get(handles.channels(index).wvc, 'String'));
    ID = {wavs{index}, wvcs(index), (w_values(index)-1)*64+wvcs(index)};
    t_values(index) = get(handles.channels(index).type, 'Value');
    type = handles.types{t_values(index)};
    types.(type)(length(types.(type))+1) = index;
    record(index) = get(handles.channels(index).rec, 'Value');
    
    names{index} = name;
    IDs(index,:) = ID;
    all_info(index,:) = [name, {ID}, type];
    
    if record(index)
        record_i(end+1) = index;
        r_info(end+1, :) = [name, {ID}, type];
    end
end

out.names = names;
out.wav_names = handles.wavs;
out.chans = wvcs;
out.type_names = handles.types;
out.w_values = w_values;
out.t_values = t_values;
out.recording = record;
out.record_i = record_i;
out.wavs = wavs;
out.types = types;
out.allowed = handles.allowed;
out.IDs = IDs;
out.all_info = all_info;
out.r_info = r_info;

varargout{1} = out;

delete(handles.selectChannel)
end

% --- Executes when user attempts to close selectChannel.
function selectChannel_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to selectChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isequal(get(hObject,'waitstatus'), 'waiting')
    uiresume(hObject);
else
    delete(hObject);
end
end

% --- Executes on button press in confirmButton.
function confirmButton_Callback(hObject, eventdata, handles)
% hObject    handle to confirmButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA
handles.allowed = true;

guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.selectChannel);
end

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.selectChannel);
end

% --- Executes on slider movement.
function extraSlider_Callback(hObject, eventdata, handles)
% hObject    handle to extraSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
y_scale = get(hObject,'Value');
location = get(handles.innerPanel,'Position');
location(2) = -y_scale*(location(4)-1);
set(handles.innerPanel,'Position',location);
end

% --- Executes on button press in addChannel.
function addChannel_Callback(hObject, eventdata, handles)
% hObject    handle to addChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
channels = handles.channels;
new_chan = length(channels)+1;

segment = setPanelSize(handles.innerPanel, 10, new_chan, false);
set(handles.extraSlider,'Value', 0);

channels(new_chan) = addTDTChannelGUI(new_chan, 'New Channel', handles.wavs, 0, handles.types, segment, handles.innerPanel);

handles.channels = setChannelsPosition(channels, segment);

guidata(hObject, handles);
end

% --- Executes on button press in removeChannel.
function removeChannel_Callback(hObject, eventdata, handles)
% hObject    handle to removeChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
channels = handles.channels;
chan = length(channels);
if chan > handles.min_channels
    delete(channels(chan).num)
    delete(channels(chan).text)
    delete(channels(chan).wav)
    delete(channels(chan).wvc)
    delete(channels(chan).type)
    delete(channels(chan).rec)
    channels(chan) = [];
    
    segment = setPanelSize(handles.innerPanel, 10, chan, false);
    set(handles.extraSlider,'Value', 0);
    
    handles.channels = setChannelsPosition(channels, segment);
end
guidata(hObject,handles)
end

function channelName1_Callback(hObject, eventdata, handles)
% hObject    handle to channelName1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of channelName1 as text
%        str2double(get(hObject,'String')) returns contents of channelName1 as a double
end

%--- Executes on selection change in typeSelect1.
function typeSelect1_Callback(hObject, eventdata, handles)
% hObject    handle to typeSelect1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns typeSelect1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from typeSelect1
end


%% ---- Extra Functions ---- %%
function channels = createChannels(parent, names, wavs, wvcs, types, record, wav_values, type_values, f_size)
    if nargin >= 8
        correspond = true;
    else
        correspond = false;
    end

    if nargin < 9
        f_size = 10;
    end
    
    segment = setPanelSize(parent, f_size, length(names), true);
    
    for index = 1:length(names)
        channels(index) = addTDTChannelGUI(index, names{index}, wavs, wvcs(index), types, segment, parent);
        if correspond
            channels(index).wav.Value = wav_values(index);
            channels(index).type.Value = type_values(index);
            channels(index).rec.Value = record(index);
        end
    end
end

function segment = setPanelSize(parent, f_size, t_size, top)
    location = get(parent,'Position');
    if t_size > f_size
        location(4) = t_size/f_size;
        segment = 1/t_size;
    else
        segment = 1/f_size;
        location(4) = 1;
    end
    if top
        location(2) = 1-location(4);
    else
        location(2) = 0;
    end
    set(parent,'Position', location);
end

function channel = addTDTChannelGUI(number, name, wavs, wvc, types, segment, parent)
    total_wavs = length(wavs);
    total_types = length(types);
    
    posi = [0 1-(segment)*number 0.05 segment];
    channel.num = uicontrol(parent, 'Style','text');
    channel.num.String = num2str(number);
    channel.num.FontSize = 14;
    channel.num.Units = 'normalized';
    channel.num.Position = posi;

    posi = [0.05 1-(segment)*number 0.35 segment];
    channel.text = uicontrol(parent, 'Style','edit');
    channel.text.String = name;
    channel.text.FontSize = 14;
    channel.text.Units = 'normalized';
    channel.text.Position = posi;

    posi = [0.42 1-(segment)*number 0.18 segment];
    channel.wav = uicontrol(parent, 'Style','popupmenu');
    channel.wav.String = wavs;
    channel.wav.FontSize = 14;
    channel.wav.Units = 'normalized';
    channel.wav.Value = total_wavs;
    channel.wav.Position = posi;
    
    posi = [0.62 1-(segment)*number 0.07 segment];
    channel.wvc = uicontrol(parent, 'Style','edit');
    channel.wvc.String = num2str(wvc);
    channel.wvc.FontSize = 14;
    channel.wvc.Units = 'normalized';
    channel.wvc.Position = posi;

    posi = [0.7 1-(segment)*number 0.25 segment];
    channel.type = uicontrol(parent, 'Style','popupmenu');
    channel.type.String = types;
    channel.type.FontSize = 14;
    channel.type.Units ='normalized';
    channel.type.Value = total_types;
    channel.type.Position = posi;
    
    posi = [0.96 1-(segment)*number 0.2 segment];
    channel.rec = uicontrol(parent, 'Style','checkbox');
    channel.rec.String = '';
    channel.rec.FontSize =14;
    channel.rec.Units = 'normalized';
    channel.rec.Value = 1;
    channel.rec.Position = posi;
end

function channels = setChannelsPosition(channels, segment)
    for index = 1:length(channels)
        posi = [0 1-(segment)*index 0.05 segment];
        channels(index).num.Position = posi;

        posi = [0.05 1-(segment)*index 0.35 segment];
        channels(index).text.Position = posi;

        posi = [0.42 1-(segment)*index 0.18 segment];
        channels(index).wav.Position = posi;

        posi = [0.62 1-(segment)*index 0.07 segment];
        channels(index).wvc.Position = posi;

        posi = [0.7 1-(segment)*index 0.25 segment];
        channels(index).type.Position = posi;

        posi = [0.96 1-(segment)*index 0.2 segment];
        channels(index).rec.Position = posi;
    end
end
