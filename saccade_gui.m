function varargout = saccade_gui(varargin)
% SACCADE_GUI MATLAB code for saccade_gui.fig
%      SACCADE_GUI, by itself, creates a new SACCADE_GUI or raises the existing
%      singleton*.
%
%      H = SACCADE_GUI returns the handle to a new SACCADE_GUI or the handle to
%      the existing singleton*.
%
%      SACCADE_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SACCADE_GUI.M with the given input arguments.
%
%      SACCADE_GUI('Property','Value',...) creates a new SACCADE_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before saccade_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to saccade_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help saccade_gui

% Last Modified by GUIDE v2.5 22-Jan-2018 19:39:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @saccade_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @saccade_gui_OutputFcn, ...
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


% --- Executes just before saccade_gui is made visible.
function saccade_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to saccade_gui (see VARARGIN)

% Choose default command line output for hand_eye_gui
handles.output = hObject;

% read in data filesdisp('Choose eye data *.bin file')
% eye
[fnSave, pnSave] = uigetfile({'*.bin'}, 'Choose eye data *.bin file ...');
if isequal(fnSave,0) || isequal(pnSave,0)
   disp('no  file chosen ... ')
   return
end
% if mat file was specified, restore gui state
[~, ~, ext] = fileparts(fnSave);

	handles.bin_filename = fullfile(pnSave, fnSave); %'/Users/peggy/Desktop/pegtas2/pegtas2_1.bin'; % must be full path for rd_cli to work
	handles.eye_data = rd(handles.bin_filename);

handles.txtFilename.String = handles.bin_filename;

samp_freq = handles.eye_data.samp_freq;
numsamps = handles.eye_data.numsamps;
t = (1:numsamps)/samp_freq;

% initialize the data in the axes
axes(handles.axes_eye)
handles.line_rh = line(t, handles.eye_data.rh.data, 'Tag', 'line_rh', 'Color', 'g');
handles.line_lh = line(t, handles.eye_data.lh.data, 'Tag', 'line_lh', 'Color', 'r');
handles.line_rv = line(t, handles.eye_data.rv.data, 'Tag', 'line_rv', 'Color', 'g', 'LineStyle', '--');
handles.line_lv = line(t, handles.eye_data.lv.data, 'Tag', 'line_lv', 'Color', 'r', 'LineStyle', '--');
ylabel('Gaze Pos (\circ)')
xlabel('Time (s)')

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes saccade_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = saccade_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% -------------------------------
function showSaccades(h, r_or_l, h_or_v, sacc_source)
eye_str = [r_or_l(1) h_or_v(1)];
tag_search_str = ['^saccade_' eye_str '_' sacc_source '.*'];
line_list = findobj(h.figure1,'-regexp', 'Tag', tag_search_str);
if isempty(line_list)
   createSaccLines(h, r_or_l, h_or_v, sacc_source);
else
   set(line_list, 'Visible', 'on');
   
end

return

function hideSaccades(h, r_or_l, h_or_v, sacc_source)
eye_str = [r_or_l(1) h_or_v(1)];
tag_search_str = ['saccade_' eye_str '_' sacc_source '.*'];
line_list = findobj(h.figure1,'-regexp', 'Tag', tag_search_str);
if ~isempty(line_list)
   set(line_list, 'Visible', 'off');
end
return

function createSaccLines(h, r_or_l, h_or_v, sacc_source)
axes(h.axes_eye)
eye_str = [r_or_l(1) h_or_v(1)];
start_ms = h.eye_data.start_times;
beg_line_color = getLineColor(h, ['saccade_' eye_str '_' sacc_source '_begin']);
end_line_color = getLineColor(h, ['saccade_' eye_str '_' sacc_source '_end']);
samp_freq = h.eye_data.samp_freq;

switch sacc_source
	case 'eyelink'
		sacc_data = h.eye_data.(eye_str).saccades; % eyelink data
		sacc_marker = 'o';
	case 'findsacc'
        % get parameter values
        thresh_a = str2double(h.edAccelThresh.String);
        acc_stop = str2double(h.edAccelStop.String);
        thresh_v = str2double(h.edVelThresh.String);
        vel_stop = str2double(h.edVelStop.String);
        gap_fp = str2double(h.edGapFP.String);
        gap_sp = str2double(h.edGapSP.String);
        vel_or_acc = h.popmenuAccelVel.Value; % 1=Accel, 2=Vel, 3=Both
        extend = str2double(h.edExtend.String);
        dataName = 'unknown';
        strict_strip = 1;
        [ptlist, pvlist] = findsaccs(h.eye_data.(eye_str).data, thresh_a, thresh_v, acc_stop, ...
			vel_stop, gap_fp, gap_sp, vel_or_acc, extend, dataName, strict_strip);
        saccstart = evalin('base','saccstart');
        saccstop = evalin('base','saccstop');
        sacc_data.sacclist.start = saccstart; % index values into data
        sacc_data.sacclist.end = saccstop;
        
        start_ms = 0;
        % convert index values to time in ms
        sacc_data.sacclist.start = (saccstart-1) / samp_freq * 1000;
        sacc_data.sacclist.end = (saccstop-1) / samp_freq * 1000;
		
		sacc_marker = '*';
end
		
for sacc_num = 1:length(sacc_data.sacclist.start)
   % saccade begin
   time1 = (sacc_data.sacclist.start(sacc_num) - start_ms)/1000; %in seconds
   y = h.eye_data.(eye_str).data(round(time1*samp_freq));
   h_beg_line = line( time1, y, 'Tag', ['saccade_' eye_str '_' sacc_source '_#' num2str(sacc_num) '_begin'], ...
      'Color', beg_line_color, 'Marker', sacc_marker, 'MarkerSize', 10);
   eye_m = uicontextmenu;
   h_beg_line.UIContextMenu = eye_m;
   uimenu(eye_m, 'Label', 'Disable Saccade', 'Callback', @disableSaccade, ...
      'Tag', ['menu_saccade_' eye_str '_' sacc_source '_#' num2str(sacc_num) '_begin']);
   
   % saccade end
   time2 = (sacc_data.sacclist.end(sacc_num) - start_ms)/1000;
   y = h.eye_data.(eye_str).data(round(time2*samp_freq));
   line( time2, y, 'Tag', ['saccade_' eye_str '_' sacc_source '_#' num2str(sacc_num) '_end'], ...
      'Color', end_line_color, 'Marker', sacc_marker, 'MarkerSize', 10);
   
   % saccade segment
   sac_start_ind = round(time1*samp_freq);
   sac_stop_ind  = round(time2*samp_freq);
   if sac_stop_ind-sac_start_ind > 2	% if start and stop are consecutive time points, then there is no segment
	   tempdata = h.eye_data.(eye_str).data;
	   segment = tempdata(sac_start_ind:sac_stop_ind);
	   time3 = maket(segment)+time1 - 1/samp_freq;
	   line(time3, segment,'Tag', ['saccade_' eye_str '_' sacc_source '_#' num2str(sacc_num) ], 'Color','b' , ...
		  'Linewidth', 1.5)
   end
end
return

%--------------------------------------
function line_color = getLineColor(handles, type)
line_color = 'y';
h_txt = findobj(handles.figure1, 'Tag', ['txt_' type]);
if ~isempty(h_txt)
   line_color = h_txt.ForegroundColor;
else
   beg_or_end = regexp(type, '(begin)|(end)|(bp)$', 'match');
   if ~isempty(beg_or_end)
      switch beg_or_end{:},
         case 'begin',
            line_color = 'g';
         case 'end'
            line_color = 'r';
		  case 'bp'
			  line_color = 'c';
      end
   end
end
return

% --- Executes on button press in tbSaccadesRightHoriz.
function tbSaccadesRightHoriz_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesRightHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value') % returns toggle state of tbSaccades
   showSaccades(handles, 'right','horizontal', 'eyelink');
else
   hideSaccades(handles, 'right','horizontal', 'eyelink');
end
return

% --- Executes on button press in tbSaccadesRightVert.
function tbSaccadesRightVert_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesRightHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'right','vertical', 'eyelink');
else
   hideSaccades(handles, 'right','vertical', 'eyelink');
end
return


% --- Executes on button press in tbSaccadesLeftHoriz.
function tbSaccadesLeftHoriz_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesLeftHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'left', 'horizontal', 'eyelink');
else
   hideSaccades(handles, 'left', 'horizontal', 'eyelink');
end
return

% --- Executes on button press in tbSaccadesLeftHoriz.
function tbSaccadesLeftVert_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesLeftHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'left', 'vertical', 'eyelink');
else
   hideSaccades(handles, 'left', 'vertical', 'eyelink');
end
return


% --- Executes on button press in tbSaccadesRightHorizFindSacc.
function tbSaccadesRightHorizFindSacc_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesRightHorizFindSacc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'right','horizontal', 'findsacc');
else
   hideSaccades(handles, 'right','horizontal', 'findsacc');
end
return



% --- Executes on button press in tbSaccadesLeftHorizFindSacc.
function tbSaccadesLeftHorizFindSacc_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesLeftHorizFindSacc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'left','horizontal', 'findsacc');
else
   hideSaccades(handles, 'left','horizontal', 'findsacc');
end
return


% --- Executes on button press in tbSaccadesRightVertFindSacc.
function tbSaccadesRightVertFindSacc_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesRightVertFindSacc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'right','vertical', 'findsacc');
else
   hideSaccades(handles, 'right','vertical', 'findsacc');
end
return


% --- Executes on button press in tbSaccadesLeftVertFindSacc.
function tbSaccadesLeftVertFindSacc_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesLeftVertFindSacc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'left','vertical', 'findsacc');
else
   hideSaccades(handles, 'left','vertical', 'findsacc');
end
return



function edAccelThresh_Callback(hObject, eventdata, handles)
% hObject    handle to edAccelThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edAccelThresh as text
%        str2double(get(hObject,'String')) returns contents of edAccelThresh as a double


% --- Executes during object creation, after setting all properties.
function edAccelThresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edAccelThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edVelThresh_Callback(hObject, eventdata, handles)
% hObject    handle to edVelThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edVelThresh as text
%        str2double(get(hObject,'String')) returns contents of edVelThresh as a double


% --- Executes during object creation, after setting all properties.
function edVelThresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edVelThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edAccelStop_Callback(hObject, eventdata, handles)
% hObject    handle to edAccelStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edAccelStop as text
%        str2double(get(hObject,'String')) returns contents of edAccelStop as a double


% --- Executes during object creation, after setting all properties.
function edAccelStop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edAccelStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edVelStop_Callback(hObject, eventdata, handles)
% hObject    handle to edVelStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edVelStop as text
%        str2double(get(hObject,'String')) returns contents of edVelStop as a double


% --- Executes during object creation, after setting all properties.
function edVelStop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edVelStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edGapFP_Callback(hObject, eventdata, handles)
% hObject    handle to edGapFP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edGapFP as text
%        str2double(get(hObject,'String')) returns contents of edGapFP as a double


% --- Executes during object creation, after setting all properties.
function edGapFP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edGapFP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edGapSP_Callback(hObject, eventdata, handles)
% hObject    handle to edGapSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edGapSP as text
%        str2double(get(hObject,'String')) returns contents of edGapSP as a double


% --- Executes during object creation, after setting all properties.
function edGapSP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edGapSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popmenuAccelVel.
function popmenuAccelVel_Callback(hObject, eventdata, handles)
% hObject    handle to popmenuAccelVel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popmenuAccelVel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popmenuAccelVel


% --- Executes during object creation, after setting all properties.
function popmenuAccelVel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popmenuAccelVel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edExtend_Callback(hObject, eventdata, handles)
% hObject    handle to edExtend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edExtend as text
%        str2double(get(hObject,'String')) returns contents of edExtend as a double


% --- Executes during object creation, after setting all properties.
function edExtend_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edExtend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbClearOldSaccs.
function pbClearOldSaccs_Callback(hObject, eventdata, handles)
% hObject    handle to pbClearOldSaccs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% clear the saccades generated by findsaccs
eye_str_list = {'rh', 'lh', 'rv', 'lv'};
for e_cnt = 1:length(eye_str_list)
	eye_str = eye_str_list{e_cnt};
	tag_search_str = ['^saccade_' eye_str '_findsacc.*'];
	line_list = findobj(handles.figure1,'-regexp', 'Tag', tag_search_str);
	if ~isempty(line_list)
		delete(line_list)
	end
end

% reset togglebuttons
handles.tbSaccadesRightHorizFindSacc.Value = 0;
handles.tbSaccadesRightVertFindSacc.Value = 0;
handles.tbSaccadesLeftHorizFindSacc.Value = 0;
handles.tbSaccadesLeftVertFindSacc.Value = 0;
return
