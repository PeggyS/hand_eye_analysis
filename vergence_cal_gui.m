function varargout = vergence_cal_gui(varargin)
% VERGENCE_CAL_GUI MATLAB code for vergence_cal_gui.fig
%      VERGENCE_CAL_GUI, by itself, creates a new VERGENCE_CAL_GUI or raises the existing
%      singleton*.
%
%      H = VERGENCE_CAL_GUI returns the handle to a new VERGENCE_CAL_GUI or the handle to
%      the existing singleton*.
%
%      VERGENCE_CAL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VERGENCE_CAL_GUI.M with the given input arguments.
%
%      VERGENCE_CAL_GUI('Property','Value',...) creates a new VERGENCE_CAL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before vergence_cal_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to vergence_cal_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help vergence_cal_gui

% Last Modified by GUIDE v2.5 16-Dec-2018 18:37:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @vergence_cal_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @vergence_cal_gui_OutputFcn, ...
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


% --- Executes just before vergence_cal_gui is made visible.
function vergence_cal_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to vergence_cal_gui (see VARARGIN)

% Choose default command line output for vergence_cal_gui
handles.output = hObject;

% read in data filesdisp('Choose eye data *.bin file')
% eye
[fnSave, pnSave] = uigetfile({'*.bin'}, 'Choose eye data *.bin file ...');
if isequal(fnSave,0) || isequal(pnSave,0)
   disp('no  file chosen ... ')
   return
end

handles.bin_filename = fullfile(pnSave, fnSave); %'/Users/peggy/Desktop/pegtas2/pegtas2_1.bin'; % must be full path for rd_cli to work
handles.eye_data = rd(handles.bin_filename);

handles.txtFileName.String = handles.bin_filename;

samp_freq = handles.eye_data.samp_freq;
numsamps = handles.eye_data.numsamps;
t = (1:numsamps)/samp_freq;

% initialize the data in the axes
axes(handles.axes_eye)
handles.line_rh = line(t, handles.eye_data.rh.pos, 'Tag', 'line_rh', 'Color', [0 .8 0]);
handles.line_lh = line(t, handles.eye_data.lh.pos, 'Tag', 'line_lh', 'Color', [0.8 0 0]);
handles.line_rv = line(t, handles.eye_data.rv.pos, 'Tag', 'line_rv', 'Color', [0 1 0]);
handles.line_lv = line(t, handles.eye_data.lv.pos, 'Tag', 'line_lv', 'Color', [1 0 0]);
ylabel('Gaze Pos (\circ)')
xlabel('Time (s)')

% if there is a result.mat file try to read it and get the ipd
res_fname = strrep(handles.bin_filename, '.bin', '_results.mat');
if exist(res_fname, 'file')
	results = load(res_fname);
	if isfield(results.testresults, 'ipd')
		handles.editIPD.String = num2str(results.testresults.ipd);
	end
end

% draw target horizontal lines
handles = init_target_lines(handles);

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = vergence_cal_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



%--------------------------------------
function handles = init_target_lines(handles)
h_editTargetAngles = findobj(handles.figure1, '-regexp', 'Tag', 'editTarget\d+Angle');
for h_cnt = 1:length(h_editTargetAngles)
	% corresponding checkbox
	chbx_tag_str = strrep(h_editTargetAngles(h_cnt).Tag, 'edit', 'checkbox');
	chbx_tag_str = strrep(chbx_tag_str, 'Angle', '');
	h_chkbx = findobj(handles.figure1, 'Tag', chbx_tag_str);
	
	angle = str2double(h_editTargetAngles(h_cnt).String);
	ud.target_angle = angle; % target angle
	ud.h_editTargetAngle = h_editTargetAngles(h_cnt);
	handles.target_line(h_cnt) = line(handles.axes_eye.XLim, [angle, angle], ...
		'Tag', 'target_line', 'UserData', ud);
	draggable(handles.target_line(h_cnt), 'v')
	
	chkbx_ud.target_line = handles.target_line(h_cnt); % save handle to target line in userdata of checkbox
	h_chkbx.UserData = chkbx_ud;
	
end
return

% ---------------------------------------------
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
   hObject.UserData = 'eyelink';
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
   hObject.UserData = 'eyelink';
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
   hObject.UserData = 'eyelink';
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
   hObject.UserData = 'eyelink';
else
   hideSaccades(handles, 'left', 'vertical', 'eyelink');
end
return


% --- Executes on button press in tbSaccadesRightHorizFindSacc.
function tbSaccadesRightHorizFindSacc_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesRightHorizFindSacc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') 
   showSaccades(handles, 'right','horizontal', 'findsaccs');
   hObject.UserData = 'findsaccs';
else
   hideSaccades(handles, 'right','horizontal', 'findsaccs');
end
return



% --- Executes on button press in tbSaccadesLeftHorizFindSacc.
function tbSaccadesLeftHorizFindSacc_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesLeftHorizFindSacc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'left','horizontal', 'findsaccs');
   hObject.UserData = 'findsaccs';
else
   hideSaccades(handles, 'left','horizontal', 'findsaccs');
end
return


% --- Executes on button press in tbSaccadesRightVertFindSacc.
function tbSaccadesRightVertFindSacc_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesRightVertFindSacc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'right','vertical', 'findsaccs');
   hObject.UserData = 'findsaccs';
else
   hideSaccades(handles, 'right','vertical', 'findsaccs');
end
return


% --- Executes on button press in tbSaccadesLeftVertFindSacc.
function tbSaccadesLeftVertFindSacc_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesLeftVertFindSacc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'left','vertical', 'findsaccs');
   hObject.UserData = 'findsaccs';
else
   hideSaccades(handles, 'left','vertical', 'findsaccs');
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
	tag_search_str = ['^saccade_' eye_str '_findsaccs.*'];
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
% reset userdata
handles.tbSaccadesRightHorizFindSacc.UserData = [];
handles.tbSaccadesRightVertFindSacc.UserData = [];
handles.tbSaccadesLeftHorizFindSacc.UserData = [];
handles.tbSaccadesLeftVertFindSacc.UserData = [];

% remove data saved in handles
eye_list = {'lh', 'rh', 'lv', 'rv'};
for e_cnt = 1:length(eye_list)
	eye_str = eye_list{e_cnt};
	if isfield(handles.eye_data.(eye_str), 'saccades')
		for s_cnt = 1:length(handles.eye_data.(eye_str).saccades)
			if strcmp(handles.eye_data.(eye_str).saccades(s_cnt).paramtype, 'findsaccs')
				handles.eye_data.(eye_str).saccades(s_cnt) = [];
				break
			end
		end
	end
end
guidata(handles.figure1, handles)
% if isfield(handles, 'findsacc_data')
% 	handles = rmfield(handles, 'findsacc_data');
% 	guidata(handles.figure1, handles)
% end

return


% --- Executes on button press in pbSaveFindSaccs.
function pbSaveFindSaccs_Callback(hObject, eventdata, handles)
% hObject    handle to pbSaveFindSaccs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fname = strrep(handles.bin_filename, '.bin', '_findsaccs.mat');
[filename, pathname] = uiputfile(fname, 'Save saccade data file');
if isequal(filename,0) || isequal(pathname,0)
	disp('User pressed cancel')
else
	disp(['Saving ', fullfile(pathname, filename)])
	eye_list = {'lh', 'rh', 'lv', 'rv'};
	for e_cnt = 1:length(eye_list)
		eye_str = eye_list{e_cnt};
		if isfield(handles.eye_data.(eye_str), 'saccades')
			for s_cnt = 1:length(handles.eye_data.(eye_str).saccades)
				if strcmp(handles.eye_data.(eye_str).saccades(s_cnt).paramtype, 'findsaccs')
					data.(eye_str).sacclist = handles.eye_data.(eye_str).saccades(s_cnt).sacclist;
				end
			end
		end
	end
					
% 	data = handles.findsacc_data;
	% remove disabled saccades
% 	data = remove_disabled_saccades(handles, data, 'findsaccs');
	params.accelThresh = handles.edAccelThresh.String;
	params.velThresh = handles.edVelThresh.String;
	params.accelStop = handles.edAccelStop.String;
	params.velStop = handles.edVelStop.String;
	params.gapFP = handles.edGapFP.String;
	params.gapSP = handles.edGapSP.String;
	params.accelVel = handles.popmenuAccelVel.Value;
	params.extend = handles.edExtend.String;
	if exist('data','var')
		save(fullfile(pathname, filename), 'data', 'params')
	else
		disp('No findsaccs saccades to save')
	end
end
return

% disabled saccades are not being removed
function data = remove_disabled_saccades(handles, data, sacc_type)
eye_str_list = {'rh', 'lh', 'rv', 'lv'};
for e_cnt = 1:length(eye_str_list)
	eye_str = eye_str_list{e_cnt};
	tag_search_str = ['^saccade_' eye_str '_' sacc_type '.*_begin$'];
	sacc_beg_lines = findobj(handles.figure1,'-regexp', 'Tag', tag_search_str);
	disabled_lines = findobj(sacc_beg_lines, 'Marker', 'x');
	if ~isempty(disabled_lines)
		for sac_num = 1:length(disabled_lines)
			sacc_time_ms = round(disabled_lines(sac_num).XData*1000 + handles.eye_data.start_times);
			sac_ind = find(data.(eye_str).sacclist.start == sacc_time_ms, 1);
			assert(~isempty(sac_ind), 'error finding saccade at %d\n', sacc_time_ms)
			data.(eye_str).start(sac_ind) = [];
			data.(eye_str).end(sac_ind) = [];
		end
	end
	
end

return


% --- Executes on button press in pbDefaultParams.
function pbDefaultParams_Callback(hObject, eventdata, handles)
% hObject    handle to pbDefaultParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.edAccelThresh.String = '800';
handles.edVelThresh.String = '20';
handles.edAccelStop.String = '100';
handles.edVelStop.String = '10';
handles.edGapFP.String = '10';
handles.edGapSP.String = '10';
handles.popmenuAccelVel.Value = 1;
handles.edExtend.String = '5';

% Update handles structure
guidata(handles.figure1, handles);
return


% --- Executes on button press in tbSaccadesRightHorizEngbert.
function tbSaccadesRightHorizEngbert_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesRightHorizEngbert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') 
   showSaccades(handles, 'right','horizontal', 'engbert');
   hObject.UserData = 'engbert';
else
   hideSaccades(handles, 'right','horizontal', 'engbert');
end
return

% --- Executes on button press in tbSaccadesLeftHorizEngbert.
function tbSaccadesLeftHorizEngbert_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesLeftHorizEngbert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') 
   showSaccades(handles, 'left','horizontal', 'engbert');
   hObject.UserData = 'engbert';
else
   hideSaccades(handles, 'left','horizontal', 'engbert');
end
return

% --- Executes on button press in tbSaccadesRightVertEngbert.
function tbSaccadesRightVertEngbert_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesRightVertEngbert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') 
   showSaccades(handles, 'right','vertical', 'engbert');
   hObject.UserData = 'engbert';
else
   hideSaccades(handles, 'right','vertical', 'engbert');
end
return

% --- Executes on button press in tbSaccadesLeftVertEngbert.
function tbSaccadesLeftVertEngbert_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesLeftVertEngbert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') 
   showSaccades(handles, 'left','vertical', 'engbert');
   hObject.UserData = 'engbert';
else
   hideSaccades(handles, 'left','vertical', 'engbert');
end
return

% --- Executes on button press in pbClearSaccsEngbert.
function pbClearSaccsEngbert_Callback(hObject, eventdata, handles)
% hObject    handle to pbClearSaccsEngbert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% clear the saccades generated by findsaccs
eye_str_list = {'rh', 'lh', 'rv', 'lv'};
for e_cnt = 1:length(eye_str_list)
	eye_str = eye_str_list{e_cnt};
	tag_search_str = ['^saccade_' eye_str '_engbert.*'];
	line_list = findobj(handles.figure1,'-regexp', 'Tag', tag_search_str);
	if ~isempty(line_list)
		delete(line_list)
	end
end

% reset togglebuttons
handles.tbSaccadesRightHorizEngbert.Value = 0;
handles.tbSaccadesRightVertEngbert.Value = 0;
handles.tbSaccadesLeftHorizEngbert.Value = 0;
handles.tbSaccadesLeftVertEngbert.Value = 0;
% and user data
handles.tbSaccadesRightHorizEngbert.UserData = [];
handles.tbSaccadesRightVertEngbert.UserData = [];
handles.tbSaccadesLeftHorizEngbert.UserData = [];
handles.tbSaccadesLeftVertEngbert.UserData = [];

% clear the saccades generated by engbert
% remove data saved in handles
eye_list = {'lh', 'rh', 'lv', 'rv'};
for e_cnt = 1:length(eye_list)
	eye_str = eye_list{e_cnt};
	if isfield(handles.eye_data.(eye_str), 'saccades')
		for s_cnt = 1:length(handles.eye_data.(eye_str).saccades)
			if strcmp(handles.eye_data.(eye_str).saccades(s_cnt).paramtype, 'engbert')
				handles.eye_data.(eye_str).saccades(s_cnt) = [];
				break
			end
		end
	end
end
guidata(handles.figure1, handles)
return



% --- Executes on button press in pbDefaultParamsEngbert.
function pbDefaultParamsEngbert_Callback(hObject, eventdata, handles)
% hObject    handle to pbDefaultParamsEngbert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.edVelFactor.String = '6';
handles.edMinSaccDur.String = '12';
handles.edInterSaccInterval.String = '20';
handles.chbxBinocular.Value = 0; 

% Update handles structure
guidata(handles.figure1, handles);
return

function edVelFactor_Callback(hObject, eventdata, handles)
% hObject    handle to edVelFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edVelFactor as text
%        str2double(get(hObject,'String')) returns contents of edVelFactor as a double


% --- Executes during object creation, after setting all properties.
function edVelFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edVelFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edMinSaccDur_Callback(hObject, eventdata, handles)
% hObject    handle to edMinSaccDur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edMinSaccDur as text
%        str2double(get(hObject,'String')) returns contents of edMinSaccDur as a double


% --- Executes during object creation, after setting all properties.
function edMinSaccDur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edMinSaccDur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbSaveEngbert.
function pbSaveEngbert_Callback(hObject, eventdata, handles)
% hObject    handle to pbSaveEngbert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fname = strrep(handles.bin_filename, '.bin', '_engbert.mat');
[filename, pathname] = uiputfile(fname, 'Save Engbert saccade data file');
if isequal(filename,0) || isequal(pathname,0)
	disp('User pressed cancel')
else
	disp(['Saving ', fullfile(pathname, filename)])
	eye_list = {'lh', 'rh', 'lv', 'rv'};
	for e_cnt = 1:length(eye_list)
		eye_str = eye_list{e_cnt};
		if isfield(handles.eye_data.(eye_str), 'saccades')
			for s_cnt = 1:length(handles.eye_data.(eye_str).saccades)
				if strcmp(handles.eye_data.(eye_str).saccades(s_cnt).paramtype, 'engbert')
					data.(eye_str).sacclist = handles.eye_data.(eye_str).saccades(s_cnt).sacclist;
				end
			end
		end
	end
% 	data = handles.engbertsacc_data;
% 	% remove disabled saccades
% 	data = remove_disabled_saccades(handles, data, 'engbert');
% 	
	params.velFactor = handles.edVelFactor.String;
	params.minSamples = handles.edMinSaccDur.String;
	params.edInterSaccInterval = handles.edInterSaccInterval.String;
	params.binocOnly = handles.chbxBinocular.Value;
	
	if exist('data','var')
		save(fullfile(pathname, filename), 'data', 'params')
	else
		disp('no Engbert saccade data to save')
	end
end
return


% --- Executes on button press in tbDataRightHoriz.
function tbDataRightHoriz_Callback(hObject, eventdata, handles)
% hObject    handle to tbDataRightHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% data & saccade lines
line_list = findobj(handles.figure1,'-regexp', 'Tag', '^.*rh.*');
tb_list = findobj(handles.figure1, '-regexp', 'Tag', 'tb.*RightHoriz.*');

visible = get(hObject,'Value');
if visible
	for tb_cnt = 1:length(tb_list)
		data_line = findobj(line_list, '-regexp', 'Tag', 'line_.*');
		set(data_line, 'Visible', 'on')
		% if the togglebutton indicates that there is saccade lines to
		% display - userData contains the saccade type (eyelink, findsaccs,
		% engbert)
		if ~isempty(tb_list(tb_cnt).UserData)
			set(tb_list(tb_cnt), 'Value', 1)
			tb_sacc_type_line_list = findobj(line_list,'-regexp', 'Tag', ['^.*' tb_list(tb_cnt).UserData '.*']);
			set(tb_sacc_type_line_list, 'Visible', 'on')
		end
	end
else
	set(line_list, 'Visible', 'off')
	set(tb_list, 'Value', 0)
end

return


% --- Executes on button press in tbDataLeftHoriz.
function tbDataLeftHoriz_Callback(hObject, eventdata, handles)
% hObject    handle to tbDataLeftHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% data & saccade lines
line_list = findobj(handles.figure1,'-regexp', 'Tag', '^.*lh.*');
tb_list = findobj(handles.figure1, '-regexp', 'Tag', 'tb.*LeftHoriz.*');

visible = get(hObject,'Value');
if visible
	for tb_cnt = 1:length(tb_list)
		data_line = findobj(line_list, '-regexp', 'Tag', 'line_.*');
		set(data_line, 'Visible', 'on')
		% if the togglebutton indicates that there is saccade lines to
		% display - userData contains the saccade type (eyelink, findsaccs,
		% engbert)
		if ~isempty(tb_list(tb_cnt).UserData)
			set(tb_list(tb_cnt), 'Value', 1)
			tb_sacc_type_line_list = findobj(line_list,'-regexp', 'Tag', ['^.*' tb_list(tb_cnt).UserData '.*']);
			set(tb_sacc_type_line_list, 'Visible', 'on')
		end
	end
else
	set(line_list, 'Visible', 'off')
	set(tb_list, 'Value', 0)
end

return
% --- Executes on button press in tbDataRightVert.
function tbDataRightVert_Callback(hObject, eventdata, handles)
% hObject    handle to tbDataRightVert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% data & saccade lines
line_list = findobj(handles.figure1,'-regexp', 'Tag', '^.*rv.*');
tb_list = findobj(handles.figure1, '-regexp', 'Tag', 'tb.*RightVert.*');

visible = get(hObject,'Value');
if visible
	for tb_cnt = 1:length(tb_list)
		data_line = findobj(line_list, '-regexp', 'Tag', 'line_.*');
		set(data_line, 'Visible', 'on')
		% if the togglebutton indicates that there is saccade lines to
		% display - userData contains the saccade type (eyelink, findsaccs,
		% engbert)
		if ~isempty(tb_list(tb_cnt).UserData)
			set(tb_list(tb_cnt), 'Value', 1)
			tb_sacc_type_line_list = findobj(line_list,'-regexp', 'Tag', ['^.*' tb_list(tb_cnt).UserData '.*']);
			set(tb_sacc_type_line_list, 'Visible', 'on')
		end
	end
else
	set(line_list, 'Visible', 'off')
	set(tb_list, 'Value', 0)
end

return
% --- Executes on button press in tbDataLeftVert.
function tbDataLeftVert_Callback(hObject, eventdata, handles)
% hObject    handle to tbDataLeftVert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% data & saccade lines
line_list = findobj(handles.figure1,'-regexp', 'Tag', '^.*lv.*');
tb_list = findobj(handles.figure1, '-regexp', 'Tag', 'tb.*LeftVert.*');

visible = get(hObject,'Value');
if visible
	for tb_cnt = 1:length(tb_list)
		data_line = findobj(line_list, '-regexp', 'Tag', 'line_.*');
		set(data_line, 'Visible', 'on')
		% if the togglebutton indicates that there is saccade lines to
		% display - userData contains the saccade type (eyelink, findsaccs,
		% engbert)
		if ~isempty(tb_list(tb_cnt).UserData)
			set(tb_list(tb_cnt), 'Value', 1)
			tb_sacc_type_line_list = findobj(line_list,'-regexp', 'Tag', ['^.*' tb_list(tb_cnt).UserData '.*']);
			set(tb_sacc_type_line_list, 'Visible', 'on')
		end
	end
else
	set(line_list, 'Visible', 'off')
	set(tb_list, 'Value', 0)
end

return


% --- Executes on button press in pbSaveCal.
function pbSaveCal_Callback(hObject, eventdata, handles)
% hObject    handle to pbSaveCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = parse_msg_file_for_targets(handles, 'sacc');
guidata(handles.figure1, handles)
return


% --- Executes on button press in pbLoadSmoothTarget.
function pbLoadSmoothTarget_Callback(hObject, eventdata, handles)
% hObject    handle to pbLoadSmoothTarget (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = parse_msg_file_for_targets(handles, 'smoothp');
guidata(handles.figure1, handles)
return


% --- Executes on button press in tbTargetV.
function tbTargetV_Callback(hObject, eventdata, handles)
% hObject    handle to tbTargetV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state 
   set(handles.line_target_y, 'Visible', 'on')
else
   set(handles.line_target_y, 'Visible', 'off')
end
return

% --- Executes on button press in tbTargetH.
function tbTargetH_Callback(hObject, eventdata, handles)
% hObject    handle to tbTargetH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state 
   set(handles.line_target_x, 'Visible', 'on')
else
   set(handles.line_target_x, 'Visible', 'off')
end
return


function edInterSaccInterval_Callback(hObject, eventdata, handles)
% hObject    handle to edInterSaccInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edInterSaccInterval as text
%        str2double(get(hObject,'String')) returns contents of edInterSaccInterval as a double


% --- Executes during object creation, after setting all properties.
function edInterSaccInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edInterSaccInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chbxBinocular.
function chbxBinocular_Callback(hObject, eventdata, handles)
% hObject    handle to chbxBinocular (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chbxBinocular



function editIPD_Callback(hObject, eventdata, handles)
% hObject    handle to editIPD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editIPD as text
%        str2double(get(hObject,'String')) returns contents of editIPD as a double


% --- Executes during object creation, after setting all properties.
function editIPD_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editIPD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuEye.
function popupmenuEye_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuEye (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuEye contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuEye


% --- Executes during object creation, after setting all properties.
function popupmenuEye_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuEye (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editTargetDistance_Callback(hObject, eventdata, handles)
% hObject    handle to editTargetDistance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTargetDistance as text
%        str2double(get(hObject,'String')) returns contents of editTargetDistance as a double


% --- Executes during object creation, after setting all properties.
function editTargetDistance_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTargetDistance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editTarget1Angle_Callback(hObject, eventdata, handles)
% hObject    handle to editTarget1Angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTarget1Angle as text
%        str2double(get(hObject,'String')) returns contents of editTarget1Angle as a double


% --- Executes during object creation, after setting all properties.
function editTarget1Angle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTarget1Angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxTarget1.
function checkboxTarget1_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxTarget1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxTarget1



function editTarget2Angle_Callback(hObject, eventdata, handles)
% hObject    handle to editTarget2Angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTarget2Angle as text
%        str2double(get(hObject,'String')) returns contents of editTarget2Angle as a double


% --- Executes during object creation, after setting all properties.
function editTarget2Angle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTarget2Angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxTarget2.
function checkboxTarget2_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxTarget2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxTarget2



function editTarget3Angle_Callback(hObject, eventdata, handles)
% hObject    handle to editTarget3Angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTarget3Angle as text
%        str2double(get(hObject,'String')) returns contents of editTarget3Angle as a double


% --- Executes during object creation, after setting all properties.
function editTarget3Angle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTarget3Angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxTarget3.
function checkboxTarget3_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxTarget3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxTarget3



function editTarget4Angle_Callback(hObject, eventdata, handles)
% hObject    handle to editTarget4Angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTarget4Angle as text
%        str2double(get(hObject,'String')) returns contents of editTarget4Angle as a double


% --- Executes during object creation, after setting all properties.
function editTarget4Angle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTarget4Angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxTarget4.
function checkboxTarget4_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxTarget4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxTarget4



function editTarget5Angle_Callback(hObject, eventdata, handles)
% hObject    handle to editTarget5Angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTarget5Angle as text
%        str2double(get(hObject,'String')) returns contents of editTarget5Angle as a double


% --- Executes during object creation, after setting all properties.
function editTarget5Angle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTarget5Angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxTarget5.
function checkboxTarget5_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxTarget5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxTarget5
