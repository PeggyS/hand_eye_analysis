function varargout = vergence_head_cal_gui(varargin)
% VERGENCE_HEAD_CAL_GUI MATLAB code for vergence_head_cal_gui.fig
%      VERGENCE_HEAD_CAL_GUI, by itself, creates a new VERGENCE_HEAD_CAL_GUI or raises the existing
%      singleton*.
%
%      H = VERGENCE_HEAD_CAL_GUI returns the handle to a new VERGENCE_HEAD_CAL_GUI or the handle to
%      the existing singleton*.
%
%      VERGENCE_HEAD_CAL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VERGENCE_HEAD_CAL_GUI.M with the given input arguments.
%
%      VERGENCE_HEAD_CAL_GUI('Property','Value',...) creates a new VERGENCE_HEAD_CAL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before vergence_head_cal_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to vergence_head_cal_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help vergence_head_cal_gui

% Last Modified by GUIDE v2.5 13-Feb-2019 18:57:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
   'gui_Singleton',  gui_Singleton, ...
   'gui_OpeningFcn', @vergence_head_cal_gui_OpeningFcn, ...
   'gui_OutputFcn',  @vergence_head_cal_gui_OutputFcn, ...
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


% --- Executes just before vergence_head_cal_gui is made visible.
function vergence_head_cal_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to vergence_head_cal_gui (see VARARGIN)

% Choose default command line output for vergence_head_cal_gui
handles.output = hObject;


% apdm sensor data
disp('Choose APDM data *.h5 file')
[fnSave, pnSave] = uigetfile({'*.h5'}, 'Choose APDM data *.h5 file ...');
if isequal(fnSave,0) || isequal(pnSave,0)
   disp('no  file chosen ... ')
   handles.hdf_filename = [];
   handles.apdm_data.sensor=[];
   return
else
	handles.hdf_filename = fullfile(pnSave, fnSave);
	handles.apdm_data = get_apdm_data(handles.hdf_filename);
end


% get the HEAD sensor number
head_sens_num = 0;
for sensor_cnt = 1:length(handles.apdm_data.sensor)
    if strcmpi(handles.apdm_data.sensor{sensor_cnt}, 'head')
        head_sens_num = sensor_cnt;
    end
end
assert(head_sens_num > 0, 'found no HEAD sensor in %s', handles.hdf_filename);


% head data
axes(handles.axes_head)
handles.line_angle = drawMagLine(handles.apdm_data, 1); % draw the L-R angle data line
xlabel('Time (s)')
ylabel('Angle (deg)')


% horizontal lines for defining left, right, & center
ymin = handles.axes_head.YLim(1);
ymax = handles.axes_head.YLim(2);
yrange = ymax - ymin;
y_line = ymin+yrange*1/4;
handles.left_cal_line = line(handles.axes_head.XLim, [y_line, y_line], ...
    'Color', 'r', 'linewidth', 2, 'Tag', 'left_cal_line');
draggable(handles.left_cal_line, 'v')
y_line = ymin+yrange*3/4;
handles.right_cal_line = line(handles.axes_head.XLim, [y_line, y_line], ...
    'Color', 'g', 'linewidth', 2, 'Tag', 'right_cal_line');
draggable(handles.right_cal_line, 'v')
y_line = ymin+yrange*2/4;
handles.center_cal_line = line(handles.axes_head.XLim, [y_line, y_line], ...
    'Color', 'k', 'linewidth', 2, 'Tag', 'center_cal_line');
draggable(handles.center_cal_line, 'v')

% vertical lines at annotations
for a_cnt = 1:length(handles.apdm_data.annot)
	x = handles.apdm_data.annot{a_cnt}.time;
	line([x x], [ymin ymax])
	text(x, ymin+yrange*0.02, handles.apdm_data.annot{a_cnt}.msg,'FontSize', 16)
end

% Update handles structure
guidata(hObject, handles);
return

% --- Outputs from this function are returned to the command line.
function varargout = vergence_head_cal_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
return

% -------------------------------------------------------------
function handles = request_vid_reader(handles)
disp('Choose a Scenelink video overlay file: ')
filefilt={'*.m4v;*.mp4;*.mov;*.avi'};
[fnSave, pnSave] = uigetfile(filefilt,'Choose a Scenelink video file.');
if isequal(fnSave,0) || isequal(pnSave,0)
   disp('no file chosen ... ')
   handles.video_reader = [];
   handles.vid_filename = [];
else
   handles.vid_filename = fullfile(pnSave, fnSave);
   handles.video_reader = VideoReader(handles.vid_filename);
end
return

% -------------------------------------------------------------
function h_line = drawMagLine(apdm_data, sensor_num)
sensor = apdm_data.sensor{sensor_num};

mag_rel_earth = apdm_RotateVector(apdm_data.mag{sensor_num}', apdm_data.orient{sensor_num}');

l_r_angle = -atan2(mag_rel_earth(:,2), mag_rel_earth(:,1)) * 180 / pi; 

h_line = line(apdm_data.time, l_r_angle, 'Tag', ['line_' sensor '_l_r_angle'], 'Color', [0.2 0.8 0.2], 'Linewidth', 1.5);

return


% -------------------------------------------------------------
function filt_data = filterData(data, samp_freq)
% samp_freq = 1/mean(diff(data.time));
nyqf = samp_freq/2;
ord = 4;
cutoff = 12;
[b,a] = butter(ord, cutoff/nyqf);
filt_data = filtfilt(b, a, data');
return


% -------------------------------------------------------------
function addLine(source, callbackdata, line_type)
% function called by menu to add a new line line_type is a string with the
% type (reach, grasp, transfer, mistake)
handles = guidata(gcf);
axes(handles.axes_head)
cursor_loc = get(handles.axes_head, 'CurrentPoint');
cursor_x = cursor_loc(1);

handles = addAxesLine(handles, cursor_x, line_type, 'on');

guidata(gcf, handles);

return

% -------------------------------------------------------------
function handles = show_annot_symbols(handles)
if isfield(handles,'apdm_data')
   annot = handles.apdm_data.annot;
   
   for annot_num = 1:length(handles.apdm_data.annot),
      line_type = ['annotation_' annot{annot_num}.msg];
%       handles = addAnnotSymbol(handles, annot{annot_num}.time, line_type, 'on');      
   end
end
return

% -------------------------------------------------------------
function handles = show_annot_lines(handles)
if isfield(handles,'apdm_data') && isfield(handles.apdm_data, 'annot');
   annot = handles.apdm_data.annot;
   
   for annot_num = 1:length(handles.apdm_data.annot),
      line_type = ['annotation_' annot{annot_num}.msg];
      handles = addAxesLine(handles, annot{annot_num}.time, line_type, 'on');      
   end
end
return




% -------------------------------------------------------------
function show_video_frame(handles, time)
% axes(handles.axes.video)
samp_freq = handles.eye_data.samp_freq;
min_time = 1/samp_freq;
sample_time = handles.sample_time;
v = handles.video_reader;
if time<min_time, time=min_time; end

% index into eyedata for the time to display
% samp_tweak = str2double(handles.samp_tweak.String);
samp_tweak = 0;
ind = round(time*handles.eye_data.samp_freq)+samp_tweak;
if ind == 0, ind = 1; end

% time in ms for this index plus the start time
abs_t_ms = (ind/samp_freq)*1000 + handles.eye_data.start_times;

% find the corresponding vFramenum
vframe_ind = find(handles.eye_data.vframes.frametime >= abs_t_ms, 1);
if isempty(vframe_ind) 
   % if not found, just use the last frame
   vframe_ind = length(handles.eye_data.vframes.frametime); 
end
vframe_num = handles.eye_data.vframes.framenum(vframe_ind);
assert(vframe_num > 0 && vframe_num < v.Duration* v.FrameRate, 'error finding video frame')

if vframe_num ~= v.UserData.current_frame_num
   v.UserData.current_frame_num = vframe_num;
   
   v.CurrentTime = (vframe_num-1) / v.FrameRate;
   vidFrame = readFrame(v);
   % readFrame increments the time after reading the frame, code here
   % makes is so it does not
   v.CurrentTime = (vframe_num-1) / v.FrameRate;
   
   image(vidFrame, 'Parent', handles.axes_video);
   handles.axes_video.Visible = 'off';
end

% v.CurrentTime = time + v.UserData.eye_data_offset;
%    
% 
% if hasFrame(v)
%    vidFrame = readFrame(v);
%    % readFrame increments the time after reading the frame, code here
%    % makes is so it does not
%    v.CurrentTime = time + v.UserData.eye_data_offset;
%    
%    image(vidFrame, 'Parent', handles.axes_video);
%    handles.axes_video.Visible = 'off';
% end

% %  eye pos overlay
% sample_time.String = num2str(ind/samp_freq);
% 
% % right
% r_eye = findobj(handles.figure1, 'Tag', 'line_right_eye_overlay');
% % samp_tweak = 0;
% if isempty(r_eye)
%     line(handles.axes_video_overlay, handles.eye_data.rh.data(ind), ...
%        handles.eye_data.rv.data(ind+samp_tweak), ...
%        'Color', 'g', 'Marker', 'o', 'MarkerSize', 20, ... %'MarkerFaceColor', 'g', ...
%        'Tag', 'line_right_eye_overlay')
% else
%    r_eye.XData = handles.eye_data.rh.data(ind);
%    r_eye.YData = handles.eye_data.rv.data(ind);
% end
% 
% % left
% l_eye = findobj(handles.figure1, 'Tag', 'line_left_eye_overlay');
% if isempty(l_eye)
%    line(handles.axes_video_overlay, handles.eye_data.lh.data(ind), ...
%       handles.eye_data.lv.data(ind+samp_tweak), ...
%       'Color', 'r', 'Marker', 'o', 'MarkerSize', 20, ... %'MarkerFaceColor', 'r', ...
%         'Tag', 'line_left_eye_overlay')
% else
%    l_eye.XData = handles.eye_data.lh.data(ind);
%    l_eye.YData = handles.eye_data.lv.data(ind);
% end

% % display eye data & video times in ms
% msg = sprintf('eye data index = %d / samp_freq = %f s + eye start = %d ', ...
%    ind, ind/samp_freq, (ind/samp_freq)*1000 + handles.eye_data.start_times);
% disp(msg)
% msg = sprintf('vid_time = %f; time-offset = %f', time + v.UserData.eye_data_offset, time);
% disp(msg)
return

function moveVideoFrame(handles, frames)
samp_freq = handles.eye_data.samp_freq;
min_time = 1/samp_freq;
max_time = min([ length(handles.eye_data.rh.data) / samp_freq, ...
   handles.video_reader.Duration+1/handles.video_reader.FrameRate]);

old_time = str2double(handles.edTime.String);
new_time= old_time + frames/handles.video_reader.FrameRate;

if new_time > min_time && new_time <= max_time
   show_video_frame(handles, new_time);
   
   updateScrubLine(handles, new_time)
   updateEdTime(handles, new_time)
end
return

function updateScrubLine(handles, time)
handles.scrub_line_eye.XData = [time, time];
adjustAxesForScrubLine(handles, time); 
if isfield(handles, 'scrub_line_hand')
   handles.scrub_line_hand.XData = [time, time];
end
if isfield(handles, 'scrub_line_head')
   handles.scrub_line_head.XData = [time, time];
end
return

% ---------------------------------------------------------------
function scrubLineMotionFcn(h_line)
xdata = get(h_line, 'XData');
t = xdata(1);

h = guidata(gcf);
% don't allow line to go beyond the data

if t < min(h.line_angle.XData)
   t = min(h.line_angle.XData);
end
if t > max(h.line_angle.XData)
   t = max(h.line_angle.XData);
end
adjustAxesForScrubLine(h, t)
show_video_frame(h, t)
updateEdTime(h, t)
return

function adjustAxesForScrubLine(handles, time)
% change the x axes limits to keep the line in view
if time < handles.axes_head.XLim(1)
   handles.axes_head.XLim(1) = time;
elseif time > handles.axes_head.XLim(2)
   handles.axes_head.XLim(2) = time;
end
return

% --- Executes on button press in pb_export.
function pb_export_Callback(hObject, eventdata, handles)
% hObject    handle to pb_export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% get file name to save
% cur_dir = pwd;
% cd ..

disp('Choose file name to save exported data')
[fnSave, pnSave] = uiputfile({'head_cal.mat'}, 'Choose export data *.mat file ...');
if isequal(fnSave,0) || isequal(pnSave,0)
   disp('no  file chosen ... ')
   cd(cur_dir)
   return
end
export_filename = fullfile(pnSave, fnSave);

head_cal.cal_hdf_filename = handles.hdf_filename;

head_cal.left = handles.left_cal_line.YData(1);
head_cal.right = handles.right_cal_line.YData(1);
head_cal.center = handles.center_cal_line.YData(1);
head_cal.dist_betw_left_right = str2double(handles.edDistBetw.String);
head_cal.dist_center_to_head = str2double(handles.edDistToHead.String);

% save data
save(export_filename, '-struct', 'head_cal');
% cd(cur_dir)
return

% --------------------------
function updateEdTime(h, time)
samp_freq = h.eye_data.samp_freq;
if time<1/samp_freq, time=samp_freq; end
time_str = sprintf('%0.3f', time);
set(h.edTime, 'String', time_str);
return


% --- Executes on button press in pbBack.
function pbBack_Callback(hObject, eventdata, handles)
% hObject    handle to pbBack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
moveVideoFrame(handles, -1);
return

% --- Executes on button press in pbForward.
function pbForward_Callback(hObject, eventdata, handles)
% hObject    handle to pbForward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
moveVideoFrame(handles, 1);
return



function edTime_Callback(hObject, eventdata, handles)
% hObject    handle to edTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edTime as text
min_time = 1/handles.eye_data.samp_freq;

time = str2double(get(hObject,'String')); % returns contents of edTime as a double
if time<min_time, time=min_time;end
updateEdTime(handles, time);
updateScrubLine(handles, time);
show_video_frame(handles, time);

% --- Executes during object creation, after setting all properties.
function edTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tbFixationsRightHoriz.
function tbFixationsRightHoriz_Callback(hObject, eventdata, handles)
% hObject    handle to tbFixationsRightHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value'), % returns toggle state of tbFixations
   showFixations(handles, 'right', 'horizontal');
else
   hideFixations(handles, 'right', 'horizontal');
end
return
% --- Executes on button press in tbFixationsRightVert.
function tbFixationsRightVert_Callback(hObject, eventdata, handles)
% hObject    handle to tbFixationsRightVert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value'), % returns toggle state of tbFixations
   showFixations(handles, 'right', 'vertical');
else
   hideFixations(handles, 'right', 'vertical');
end
return

% --- Executes on button press in tbFixationsLeftHoriz.
function tbFixationsLeftHoriz_Callback(hObject, eventdata, handles)
% hObject    handle to tbFixationsLeftHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tbFixationsLeftHoriz
if get(hObject,'Value'), % returns toggle state of tbFixations
   showFixations(handles, 'left', 'horizontal');
else
   hideFixations(handles, 'left', 'horizontal');
end
return

% --- Executes on button press in tbFixationsLeftVert.
function tbFixationsLeftVert_Callback(hObject, eventdata, handles)
% hObject    handle to tbFixationsLeftVert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value'), % returns toggle state of tbFixations
   showFixations(handles, 'left','vertical');
else
   hideFixations(handles, 'left','vertical');
end
% Hint: get(hObject,'Value') returns toggle state of tbFixationsLeftVert

% --- Executes on button press in tbSaccadesRightHoriz.
function tbSaccadesRightHoriz_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesRightHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value'), % returns toggle state of tbSaccades
   showSaccades(handles, 'right','horizontal');
else
   hideSaccades(handles, 'right','horizontal');
end
return

% --- Executes on button press in tbSaccadesRightVert.
function tbSaccadesRightVert_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesRightHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value'), % returns toggle state of tbFixations
   showSaccades(handles, 'right','vertical');
else
   hideSaccades(handles, 'right','vertical');
end
return


% --- Executes on button press in tbSaccadesLeftHoriz.
function tbSaccadesLeftHoriz_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesLeftHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'left', 'horizontal');
else
   hideSaccades(handles, 'left', 'horizontal');
end
return

% --- Executes on button press in tbSaccadesLeftHoriz.
function tbSaccadesLeftVert_Callback(hObject, eventdata, handles)
% hObject    handle to tbSaccadesLeftHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value') % returns toggle state of tbFixations
   showSaccades(handles, 'left', 'vertical');
else
   hideSaccades(handles, 'left', 'vertical');
end
return

% --- Executes on button press in tbExcludeBlinks.
function tbExcludeBlinks_Callback(hObject, eventdata, handles)
% hObject    handle to tbExcludeBlinks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value') %returns toggle state of tbExcludeBlinks
   showBlinks(handles)
else
   hideBlinks(handles)
end
return

% --- Executes on button press in tbAnnotations.
function tbAnnotations_Callback(hObject, eventdata, handles)
% hObject    handle to tbAnnotations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value') % returns toggle state of tbFixations
   showAnnotations(handles);
   hObject.String = 'Hide Annotations';
else
   hideAnnotations(handles);
   hObject.String = 'Show Annotations';
end
return


% --- Executes during object creation, after setting all properties.
function samp_tweak_CreateFcn(hObject, eventdata, handles)
% hObject    handle to samp_tweak (see GCBO)

% --- Executes on button press in back1samp.
function back1samp_Callback(hObject, eventdata, handles)
time = str2double(handles.edTime.String);
samp_tweak = str2double(handles.samp_tweak.String);
samp_freq = handles.eye_data.samp_freq;
vid_f_rate = handles.video_reader.FrameRate;
fell_off_edge     = time + (samp_tweak-1)/samp_freq <= 1/samp_freq;
fell_out_of_frame = abs(samp_tweak) > fix(samp_freq/vid_f_rate);

if fell_off_edge || fell_out_of_frame
   handles.samp_tweak.String = num2str( 0 );
   return;
end
handles.samp_tweak.String = num2str(samp_tweak-1);
show_video_frame(handles, time)
return

% --- Executes on button press in ahead1samp.
function ahead1samp_Callback(hObject, eventdata, handles)
time = str2double(handles.edTime.String);
samp_tweak = str2double(handles.samp_tweak.String);
samp_freq = handles.eye_data.samp_freq;
vid_f_rate = handles.video_reader.FrameRate;
numsamps = handles.eye_data.numsamps;
max_t = numsamps/samp_freq;

fell_off_edge     = (time + (samp_tweak+1)/samp_freq >= max_t);
fell_out_of_frame = abs(samp_tweak) > fix(samp_freq/vid_f_rate);

if fell_off_edge || fell_out_of_frame
   handles.samp_tweak.String = num2str( 0 );
   show_video_frame(handles, time)
   return;
end
handles.samp_tweak.String = num2str(samp_tweak+1);
show_video_frame(handles, time)
return


% --- Executes during object creation, after setting all properties.
function samp_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in tbPlayPause.
function tbPlayPause_Callback(hObject, eventdata, handles)
% hObject    handle to tbPlayPause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

play_pause = get(hObject,'Value'); % returns toggle state of tbPlayPause
if play_pause
    % value = 1 = just set to pause
    % change button text to play
    hObject.String = 'Play';
else
    % value = 0 = just set to play
    % change button to pause
    hObject.String = 'Pause';
end

playback_speed = str2double(get(handles.edPlaybackSpeed, 'String'));
h_scrub_line = findobj(handles.axes_head, 'Tag', 'scrub_line_eye');
h_data_line = findobj(handles.axes_head, 'Tag', 'line_HEAD_l_r_angle');
incr = 0.1 * playback_speed;
while strcmp(hObject.String, 'Pause') && h_scrub_line.XData(1) <= max(h_data_line.XData)
   h_scrub_line.XData = h_scrub_line.XData + incr;
   scrubLineMotionFcn(h_scrub_line)
   drawnow
end

% stop if we reach the end of the data
if h_scrub_line.XData >= max(h_data_line.XData)
   hObject.String = 'Play';
end

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
switch eventdata.Key
    case 'w'	% close window
        if length(eventdata.Modifier) == 1
            switch eventdata.Modifier{1}
                case 'command'
					delete(hObject);

            end
        end
	case 'r'	% recalc lines
% 		pbReCalc_Callback(handles.pbReCalc, eventdata, handles)
    case 'rightarrow'	% next epoch
		pbForward_Callback(handles.pbForward, eventdata, handles)
    case 'leftarrow'	% previous epoch
		pbBack_Callback(handles.pbBack, eventdata, handles)
end



function edPlaybackSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to edPlaybackSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edPlaybackSpeed as text
%        str2double(get(hObject,'String')) returns contents of edPlaybackSpeed as a double


% --- Executes during object creation, after setting all properties.
function edPlaybackSpeed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edPlaybackSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chbx_analyze_1.
function chbx_analyze_1_Callback(hObject, eventdata, handles)
% hObject    handle to chbx_analyze_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chbx_analyze_1


% --- Executes on button press in chbx_analyze_2.
function chbx_analyze_2_Callback(hObject, eventdata, handles)
% hObject    handle to chbx_analyze_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chbx_analyze_2


% --- Executes on button press in chbx_analyze_3.
function chbx_analyze_3_Callback(hObject, eventdata, handles)
% hObject    handle to chbx_analyze_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chbx_analyze_3


% --- Executes on button press in rbSingle.
function rbSingle_Callback(hObject, eventdata, handles)
% hObject    handle to rbSingle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get(hObject,'Value')  % returns toggle state of rbSingle


% --- Executes on button press in rbTriple.
function rbTriple_Callback(hObject, eventdata, handles)
% hObject    handle to rbTriple (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rbTriple

% --- Executes on button press in pbSave.
function pbSave_Callback(hObject, eventdata, handles)
% hObject    handle to pbSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
save_state(handles)

function save_state(handles)

% set a default location
filename = strrep(handles.bin_filename, '.bin', '_gui.mat');

% request where to save 
[filename, pathname] = uiputfile(filename, 'Save as');
if isequal(filename, 0) || isequal(pathname, 0),
	disp('Not saving. User canceled.');
	return;
end

disp(['Saving gui state and data to ' filename])

state.chbx_analyze_3.Value = handles.chbx_analyze_3.Value;
state.chbx_analyze_2.Value = handles.chbx_analyze_2.Value;
state.chbx_analyze_1.Value = handles.chbx_analyze_1.Value;
state.samp_tweak.String = handles.samp_tweak.String;
state.tbAnnotations.Value = handles.tbAnnotations.Value;
state.edPlaybackSpeed.String = handles.edPlaybackSpeed.String;
state.tbExcludeBlinks.Value = handles.tbExcludeBlinks.Value;
state.tbSaccadesLeftVert.Value = handles.tbSaccadesLeftVert.Value;
state.tbSaccadesRightVert.Value = handles.tbSaccadesRightVert.Value;
state.tbSaccadesLeftHoriz.Value = handles.tbSaccadesLeftHoriz.Value;
state.tbSaccadesRightHoriz.Value = handles.tbSaccadesRightHoriz.Value;
state.tbFixationsLeftVert.Value = handles.tbFixationsLeftVert.Value;
state.tbFixationsRightVert.Value = handles.tbFixationsRightVert.Value;
state.tbFixationsLeftHoriz.Value = handles.tbFixationsLeftHoriz.Value;
state.tbFixationsRightHoriz.Value = handles.tbFixationsRightHoriz.Value;
state.edTime.String = handles.edTime.String;
state.rbSingle.Value = handles.rbSingle.Value;
state.rbTriple.Value = handles.rbTriple.Value;
state.bin_filename = handles.bin_filename;
state.hdf_filename = handles.hdf_filename;
state.vid_filename = handles.vid_filename;
state.eye_data = handles.eye_data;
state.apdm_data = handles.apdm_data;

% axes limits
state.scrub_line_eye.XData = handles.scrub_line_eye.XData;

% saccades
sacc_lines = findobj(handles.axes_head, '-regexp', 'Tag', 'sacc.*');
% fixations
% blinks
% annotations (mistakes)
% exclude patches
% analyze patches
% moves/reaches

save(fullfile(pathname,filename), 'state')
return


% --- Executes on button press in pbLoad.
function pbLoad_Callback(hObject, eventdata, handles)
% hObject    handle to pbLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = restore_state(handles);
guidata(handles.figure1, handles)

function handles = restore_state(handles, varargin)
% optional input - filename, then the dialog box asking for the filename
% will not be displayed

if nargin > 1
    filename = varargin{1};
else
    [filename, pathname] = uigettfile(filename, 'Load GUI Data');
    if isequal(filename, 0) || isequal(pathname, 0),
        disp('Not saving. User canceled.');
        return;
    end
    filename = fullfile(pathname,filename);
end
if ~exist(filename, 'file')
    disp(['Error loading gui mat file ' filename])
    return
end
disp(['Loading gui state and data from ' filename])
load(filename);

handles.chbx_analyze_3.Value = state.chbx_analyze_3.Value;
handles.chbx_analyze_2.Value = state.chbx_analyze_2.Value;
handles.chbx_analyze_1.Value = state.chbx_analyze_1.Value;
handles.samp_tweak.String = state.samp_tweak.String;
handles.tbAnnotations.Value = state.tbAnnotations.Value;
handles.edPlaybackSpeed.String = state.edPlaybackSpeed.String;
handles.tbExcludeBlinks.Value = state.tbExcludeBlinks.Value;
handles.tbSaccadesLeftVert.Value = state.tbSaccadesLeftVert.Value;
handles.tbSaccadesRightVert.Value = state.tbSaccadesRightVert.Value;
handles.tbSaccadesLeftHoriz.Value = state.tbSaccadesLeftHoriz.Value;
handles.tbSaccadesRightHoriz.Value = state.tbSaccadesRightHoriz.Value;
handles.tbFixationsLeftVert.Value = state.tbFixationsLeftVert.Value;
handles.tbFixationsRightVert.Value = state.tbFixationsRightVert.Value;
handles.tbFixationsLeftHoriz.Value = state.tbFixationsLeftHoriz.Value;
handles.tbFixationsRightHoriz.Value = state.tbFixationsRightHoriz.Value;
handles.edTime.String = state.edTime.String;
handles.rbSingle.Value = state.rbSingle.Value;
handles.rbTriple.Value = state.rbTriple.Value;
handles.bin_filename = state.bin_filename;
handles.hdf_filename = state.hdf_filename;
handles.vid_filename = state.vid_filename;
handles.eye_data = state.eye_data;
handles.apdm_data = state.apdm_data;
handles.restore_data.scrub_line_eye.XData = state.scrub_line_eye.XData;

return



function edDistBetw_Callback(hObject, eventdata, handles)
% hObject    handle to edDistBetw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edDistBetw as text
%        str2double(get(hObject,'String')) returns contents of edDistBetw as a double


% --- Executes during object creation, after setting all properties.
function edDistBetw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edDistBetw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edDistToHead_Callback(hObject, eventdata, handles)
% hObject    handle to edDistToHead (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edDistToHead as text
%        str2double(get(hObject,'String')) returns contents of edDistToHead as a double


% --- Executes during object creation, after setting all properties.
function edDistToHead_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edDistToHead (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
