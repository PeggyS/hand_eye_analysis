function varargout = hand_eye_gui(varargin)
% HAND_EYE_GUI MATLAB code for hand_eye_gui.fig
%      HAND_EYE_GUI, by itself, creates a new HAND_EYE_GUI or raises the existing
%      singleton*.
%
%      H = HAND_EYE_GUI returns the handle to a new HAND_EYE_GUI or the handle to
%      the existing singleton*.
%
%      HAND_EYE_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HAND_EYE_GUI.M with the given input arguments.
%
%      HAND_EYE_GUI('Property','Value',...) creates a new HAND_EYE_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before hand_eye_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to hand_eye_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help hand_eye_gui

% Last Modified by GUIDE v2.5 18-Apr-2019 19:14:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
   'gui_Singleton',  gui_Singleton, ...
   'gui_OpeningFcn', @hand_eye_gui_OpeningFcn, ...
   'gui_OutputFcn',  @hand_eye_gui_OutputFcn, ...
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


% --- Executes just before hand_eye_gui is made visible.
function hand_eye_gui_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to hand_eye_gui (see VARARGIN)

% Choose default command line output for hand_eye_gui
handles.output = hObject;
guidata(hObject, handles);

% request what type of data/analysis
str = {'Scenecam task with Opal', 'Scenecam task without Opal', ...
	'Saccades with Opal', 'Saccades without Opal', ...
	'Smooth Pursuit with Opal', 'Smooth Pursuit without Opal', ...
	'Picture Difference with Opal', 'Picture Difference without Opal', ...
	'Reading Text with Opal', 'Reading Text without Opal', ...
	'Gaze Holding with Opal', 'Gaze Holding without Opal', ...
	'Eccentric Gaze Holding with Opal', 'Eccentric Gaze Holding without Opal', ...
	'Vergence with Opal', 'Vergence without Opal', ...
	'Restore Previous Analysis'};
[choice_num, ok] = listdlg('PromptString', 'Select the type of experiment', ...
	'SelectionMode','single','ListString',str);
if ~ok
	% user canceled - just quit
	return
end
disp(['Analysis choice = ' num2str(choice_num), ' - ' str{choice_num}])

if choice_num == 17 % restore data
	[fnSave, pnSave] = uigetfile({'*.mat'}, 'Choose *.mat file ...');
	if isequal(fnSave,0) || isequal(pnSave,0)
		disp('no  file chosen ... ')
		return
	end
	handles = read_restore_state(handles, fullfile(pnSave, fnSave));
else % all other choices, read in *.bin file for eye data
	disp('Choose eye data *.bin file ...')
	[fnSave, pnSave] = uigetfile({'*.bin';'*.edf'}, 'Choose eye data *.bin file ...');
	if isequal(fnSave,0) || isequal(pnSave,0)
		disp('no  file chosen ... ')
		return
	end
	handles.bin_filename = fullfile(pnSave, fnSave); %'/Users/peggy/Desktop/pegtas2/pegtas2_1.bin'; % must be full path for rd_cli to work
	handles.eye_data = rd(handles.bin_filename, 'batch', 'nofilt');
	handles.eye_data = enable_all_saccades(handles.eye_data);
end


% % if mat file was specified, restore gui state
% [~, ~, ext] = fileparts(fnSave);
% if strcmp(ext, '.mat')
% 	handles = read_restore_state(handles, fullfile(pnSave, fnSave));
% else
% 	handles.bin_filename = fullfile(pnSave, fnSave); %'/Users/peggy/Desktop/pegtas2/pegtas2_1.bin'; % must be full path for rd_cli to work
% 	handles.eye_data = rd(handles.bin_filename);
% end
handles.txtFilename.String = handles.bin_filename;

samp_freq = handles.eye_data.samp_freq;
numsamps = handles.eye_data.numsamps;
t = (1:numsamps)/samp_freq;
if isfield(handles, 'restore_data')
	if isfield(handles.restore_data, 'scrub_line_eye' ) && ...
			~isempty(handles.restore_data.scrub_line_eye.XData)
		updateEdTime(handles, handles.restore_data.scrub_line_eye.XData(1));
	end
else
	updateEdTime(handles, 1/samp_freq);
end


if choice_num==1 || choice_num==3 || choice_num==5 || choice_num==7  || choice_num==9 ...
		|| choice_num==11 || choice_num==13 || choice_num==15  % there is opal/apdm data to read in
	% if ~isfield(handles, 'restore_data')
	% apdm sensor data - we can handle up to 2 sensors
	disp('Choose APDM data *.h5 file')
	[fnSave, pnSave] = uigetfile({'*.h5'}, 'Choose APDM data *.h5 file ...');
	if isequal(fnSave,0) || isequal(pnSave,0)
		disp('no  file chosen ... ')
		handles.hdf_filename = [];
		handles.apdm_data.sensor=[];
	else
		handles.hdf_filename = fullfile(pnSave, fnSave);
		handles.apdm_data = get_apdm_data(handles.hdf_filename);
		% apdm_data.time begins at 0. this corresponds to eyelink data time
		% of approx first sample, which is t=0.004. The actual time to
		% synchronize is in the msg file with one of the lines:
		% 	   MSG	1243722 SCENELINK_TTL [OUT] START_TTL address=0x378 value=0x1
		%		MSG	1243723 !CMD 0 write_ioport 0x378 1
		% the !cmd 0 write_ioport is probably the actual time of the ttl signal
		% written to the port
		% start of eyelink data was
		% START	1243722 	SAMPLES	EVENTS
		% It's a 1 ms time delay for this experiment, but may matter in other
		% experiments.
		%
		% FIXME - write something to offset the apdm_data.time vector so it
		% cooincides with the eyedata t = (1:numsamps)/samp_freq; vector
		
	end
end

switch choice_num
	case {1 2} % scenecam: read in video data
		handles = request_vid_reader(handles);
	case {3 4} % saccades: read in target data
		handles = parse_msg_file_for_targets(handles, 'sacc');
		
	case {5 6} % smooth pursuit
		handles = parse_msg_file_for_targets(handles, 'smoothp');
		
	case {7 8} % picture diff: read in picture and mouse click data
		handles = get_image_and_clicks(handles);
	case {9 10} % reading text: read in text page image
		handles = get_page_text_image(handles);
	case {11 12} % gaze holding:
		% 		handles = handles;
	case {13 14} % eccentric gaze holding
		handles = parse_msg_file_for_targets(handles, 'ecc_gaze');
	case {15 16} % vergence: get led data
		handles = get_led_data(handles);
	case 17 % restoring data from *_gui.mat
		% change the choice_num corresponding to the saved .mat
		if isfield(handles, 'vid_filename')
			choice_num = 1;
			% try to reload the vid_file
			try
				handles.video_reader = VideoReader(handles.vid_filename);
				handles.video_reader.UserData.current_frame_num = 1;
			catch ME
				if strcmp(ME.identifier, 'MATLAB:audiovideo:VideoReader:FileNotFound')
					disp(['Restoring video file ' handles.vid_filename ' not found.'])
					handles = request_vid_reader(handles);
					handles.video_reader.UserData.current_frame_num = 1;
				end
			end
		elseif isfield(handles, 'target_data')
			choice_num = 3;
		elseif isfield(handles, 'click_data_tbl')
			choice_num = 7;
		elseif isfield(handles, 'led_data_tbl')
			choice_num = 15;
		end
		
end

% if ~isfield(handles, 'restore_data')
%     % video
%     handles = request_vid_reader(handles);
% else
%     % try to reload the vid_file
%     try
%         handles.video_reader = VideoReader(handles.vid_filename);
%     catch ME
%         if strcmp(ME.identifier, 'MATLAB:audiovideo:VideoReader:FileNotFound')
%             disp(['Restoring video file ' handles.vid_filename ' not found.'])
%             handles = request_vid_reader(handles);
%         end
%     end
% end

% % used to syncronize the video start time to the data start time
% handles.video_reader.UserData.current_frame_num = 1;

% size the axes depending upon how many sensor there are to display
handles = resizeAxes(handles);

% initialize the data in the axes
axes(handles.axes_eye)

if choice_num == 15 || choice_num == 16 % vergence
	% calibrate the data with the vergence cal_info
	% look for the Left & Right_verg_cal.mat files
	if ~isempty(handles.eye_data.rh.pos)
		[~, rcal_fname] = system('mdfind -onlyin ../ -name Right_verg_cal.mat');
		handles.rcal_fname = strtrim(rcal_fname);
		if isempty(handles.rcal_fname)
			disp('Choose right eye vergence cal mat.')
			[fnSave, pnSave] = uigetfile({'*.mat'},'Choose right eye vergence cal mat.');
			if isequal(fnSave,0) || isequal(pnSave,0)
				disp('no file chosen ... ')
			else
				handles.rcal_fname = fullfile(pnSave, fnSave);
			end
		end
		
		if ~isempty(handles.rcal_fname)
			load(handles.rcal_fname);
			handles.rcal_info = cal_info;
			handles.eye_data.rh.pos_verge_cal = apply_vergence_cal(handles.eye_data.rh.pos, handles.rcal_info, false);
			handles.line_rh = line(t, handles.eye_data.rh.pos_verge_cal, 'Tag', 'line_rh', 'Color', 'g');
		else
			handles.line_rh = line(t, handles.eye_data.rh.pos, 'Tag', 'line_rh', 'Color', 'g');
		end
	end
	
	if ~isempty(handles.eye_data.lh.pos)
		[~, lcal_fname] = system('mdfind -onlyin ../ -name Left_verg_cal.mat');
		handles.lcal_fname = strtrim(lcal_fname);
		if isempty(handles.lcal_fname)
			disp('Choose left eye vergence cal mat.')
			[fnSave, pnSave] = uigetfile({'*.mat'},'Choose left eye vergence cal mat.');
			if isequal(fnSave,0) || isequal(pnSave,0)
				disp('no file chosen ... ')
			else
				handles.lcal_fname = fullfile(pnSave, fnSave);
			end
		end
		if ~isempty(handles.lcal_fname)
			load(handles.lcal_fname);
			handles.lcal_info = cal_info;
			handles.eye_data.lh.pos_verge_cal = apply_vergence_cal(handles.eye_data.lh.pos, handles.lcal_info, false);
			handles.line_lh = line(t, handles.eye_data.lh.pos_verge_cal, 'Tag', 'line_lh', 'Color', 'r');
		else
			handles.line_lh = line(t, handles.eye_data.lh.pos, 'Tag', 'line_lh', 'Color', 'r');
		end
	end
	
	if ~isempty(handles.eye_data.lh.pos) && ~isempty(handles.eye_data.rh.pos)
		% lh-rh = vergence
		verg = handles.line_lh.YData - handles.line_rh.YData;
		
		% (lh+rh)/2 = conjugate
		conj = (handles.line_lh.YData + handles.line_rh.YData)/2;
		handles.line_vergence = line(t, verg, 'Tag', 'line_vergence', 'Color', 'b');
		handles.line_conjugate = line(t, conj, 'Tag', 'line_conjugate', 'Color', 'c');
		
	end
	handles = create_verg_vel_lines(handles);
	
else
	if ~isempty(handles.eye_data.rh.pos)
		handles.line_rh = line(t, handles.eye_data.rh.pos, 'Tag', 'line_rh', 'Color', 'g');
	end
	if ~isempty(handles.eye_data.lh.pos)
		handles.line_lh = line(t, handles.eye_data.lh.pos, 'Tag', 'line_lh', 'Color', 'r');
	end
	ylabel('Gaze Pos (\circ)')
end
if ~isempty(handles.eye_data.rv.pos)
	handles.line_rv = line(t, handles.eye_data.rv.pos, 'Tag', 'line_rv', 'Color', 'g', 'LineStyle', '--');
end
if ~isempty(handles.eye_data.lv.pos)
	handles.line_lv = line(t, handles.eye_data.lv.pos, 'Tag', 'line_lv', 'Color', 'r', 'LineStyle', '--');
end

% 	ylabel('Gaze Pos (\circ)')
% end


if isfield(handles,'apdm_data') && ~isempty(handles.apdm_data.sensor)
   axes(handles.axes_hand) % 1st axis is called hand no matter what the sensor is
   %drawSensorAccelLines(handles.apdm_data, 1);
%    drawSensorCombinedVelocityLine(handles.apdm_data, 1)
     if strcmpi(handles.apdm_data.sensor{1}, 'head')
         % check for calibaration data in head_cal.mat
         cur_dir = pwd;
         cd ..
         parent_dir = pwd;
         cd(cur_dir)
         calfile = fullfile(parent_dir, 'head_cal.mat');
         if exist(calfile, 'file')
             disp(['using head calibration file ' calfile])
             handles.head_cal = load(calfile);
             handles.head_cal.filename = calfile;
         else
             disp('no head calibration file')
         end
%          drawMagLine(handles, 1)
		 drawHeadAngleLine(handles, 1)
     end
%    drawCorrectedVelocityLine(handles.apdm_data, 1)
%    scale_norm_gyro_corrected_vel_to_axes(handles.axes_hand)
   
   % if pursuit, add a head movement threshold line
   if choice_num == 5
	   add_head_vel_threshold_line(handles.axes_hand)
   end
     
   handles.linkprop_list(1) = linkprop([handles.axes_eye, handles.axes_hand ], 'XLim');

	if length(handles.apdm_data.sensor) > 1
	   axes(handles.axes_head) % 2nd axis is called head no matter what the sensor is
	   drawCorrectedVelocityLine(handles.apdm_data, 2);
	   handles.linkprop_list(end+1) = linkprop([handles.axes_eye, handles.axes_head ], 'XLim');
	end
	if length(handles.apdm_data.sensor) > 2
	   axes(handles.axes_sensor3) % 3rd axis is called sensor3 no matter what the sensor is
	   drawCorrectedVelocityLine(handles.apdm_data, 3);
	   handles.linkprop_list(end+1) = linkprop([handles.axes_eye, handles.axes_sensor3 ], 'XLim');
	end
end
% lines
handles = show_annot_lines(handles);

% annotations of apdm data
% handles = show_annot_symbols(handles);

switch choice_num
	case {1 2}

		if isa(handles.video_reader,'VideoReader')
			% video overlay
			handles.axes_video_overlay.Color = 'none';

			xmin_max = handles.eye_data.h_pix_z / handles.eye_data.h_pix_deg;
			ymin_max = handles.eye_data.v_pix_z / handles.eye_data.v_pix_deg;
			handles.axes_video_overlay.XLim = [-xmin_max xmin_max];
			handles.axes_video_overlay.YLim = [-ymin_max ymin_max];

			% video
			show_video_frame(handles, 1/samp_freq)
			if isfield(handles, 'restore_data')
				handles = add_scrub_lines(handles, handles.restore_data.scrub_line_eye.XData(1));
			else
				handles = add_scrub_lines(handles, 1/handles.eye_data.samp_freq);
			end
		end
	case {3 4 5 6} % saccade or smooth pursuit targets
		% remove video axes
		delete(handles.axes_video_overlay)
		delete(handles.axes_video)
		% make extraneous objects invisible
		obj_list = [handles.tbPlayPause, handles.text29, handles.text2, handles.edTime, handles.text2, handles.text23, ...
					handles.edPlaybackSpeed, handles.ahead1samp, handles.back1samp, handles.samp_tweak, ...
					handles.text21, handles.text20, handles.pbBack, handles.pbForward, ...
					handles.txtVergence, handles.tbConjugate, handles.tbVergence, handles.tbVergenceVelocity];
		set(obj_list, 'Visible', 'off')
 		% make eye data axes wider
		handles = widen_axes(handles);
		% show toggle buttons 
		set(handles.txtSaccadeTargets, 'Visible', 'on')
		set(handles.tbTargetH, 'Visible', 'on')
		set(handles.tbTargetV, 'Visible', 'on')
	case {7 8 9 10} % picture diff & read text
		if isfield(handles, 'im_data')
			imshow(handles.im_data, 'Parent', handles.axes_video, 'XData', [0 1024], 'YData', [0 768] )
		else
			save('missing_im_data.mat', handles)
			disp('Error: im_data is missing. Handles struct is saved in the file missing_im_data.mat. Send to Peggy to troubleshoot.')
			return
		end
% 		handles.axes_video.Visible = 'on';
		obj_list = [handles.txtVergence, handles.tbConjugate, handles.tbVergence, handles.tbVergenceVelocity];
		set(obj_list, 'Visible', 'off')
		% eye position overlay on pciture
		handles.axes_video_overlay.Color = 'none';
		handles.axes_video_overlay.Visible = 'off';
%  		xmin_max = handles.eye_data.h_pix_z / handles.eye_data.h_pix_deg;
%  		ymin_max = handles.eye_data.v_pix_z / handles.eye_data.v_pix_deg;
		xmin_max = handles.eye_data.h_pix_z / 30;
 		ymin_max = handles.eye_data.v_pix_z / 30;

		handles.axes_video_overlay.XLim = [-xmin_max xmin_max];
		handles.axes_video_overlay.YLim = [-ymin_max ymin_max];
		display_eye_pos_overlay(handles, 1/samp_freq)
		% scrub line
		if isfield(handles, 'restore_data')
			handles = add_scrub_lines(handles, handles.restore_data.scrub_line_eye.XData(1));
		else
			handles = add_scrub_lines(handles, 1/handles.eye_data.samp_freq);
		end
		if choice_num==7 || choice_num==8
			% mouse clicks
			handles = display_mouse_clicks(handles);
			% region of interest grid
			handles = add_pict_diff_roi_grid(handles);
		end
		
	case {11 12 13 14} % gaze holding
		% remove video axes
		delete(handles.axes_video_overlay)
		delete(handles.axes_video)
		% make extraneous objects invisible
		obj_list = [handles.tbPlayPause, handles.text29, handles.text2, handles.edTime, handles.text2, handles.text23, ...
					handles.edPlaybackSpeed, handles.ahead1samp, handles.back1samp, handles.samp_tweak, ...
					handles.text21, handles.text20, handles.pbBack, handles.pbForward, ...
					handles.txtVergence, handles.tbConjugate, handles.tbVergence, handles.tbVergenceVelocity, ...
					handles.tbLHVel, handles.tbRHVel];
		set(obj_list, 'Visible', 'off')
 		% make eye data axes wider
		handles = widen_axes(handles);
		
	case {15 16} % vergence
		% remove video axes
		delete(handles.axes_video_overlay)
		delete(handles.axes_video)
		% make extraneous objects invisible
		obj_list = [handles.tbPlayPause, handles.text29, handles.text2, handles.edTime, handles.text2, handles.text23, ...
					handles.edPlaybackSpeed, handles.ahead1samp, handles.back1samp, handles.samp_tweak, ...
					handles.text21, handles.text20, handles.pbBack, handles.pbForward, handles.uibgReachType];
		set(obj_list, 'Visible', 'off')
		obj_list = [handles.txtVergence, handles.tbConjugate, handles.tbVergence, handles.tbVergenceVelocity, ...
					handles.tbLHVel, handles.tbRHVel];
		set(obj_list, 'Visible', 'on')
 		% make eye data axes wider
		handles = widen_axes(handles);
end

	

% uicontextmenu to axes
eye_m = uicontextmenu;
handles.axes_eye.UIContextMenu = eye_m;
uimenu(eye_m, 'Label', 'Exclude Data', 'Callback', {@createBox, [], 'exclude'});
uimenu(eye_m, 'Label', 'Analyze Data 1', 'Callback', {@createBox, [], 'analysis_1'});
uimenu(eye_m, 'Label', 'Analyze Data 2', 'Callback', {@createBox, [], 'analysis_2'});
uimenu(eye_m, 'Label', 'Analyze Data 3', 'Callback', {@createBox, [], 'analysis_3'});

if isfield(handles, 'apdm_data')
	if ~isempty(handles.apdm_data.sensor)
		hand_m = uicontextmenu;
		handles.axes_hand.UIContextMenu = hand_m;
	% 	uimenu(hand_m, 'Label', 'Add Move', 'Callback', {@addMove, handles.axes_hand})
		uimenu(hand_m, 'Label', 'Add Mistake', 'Callback', {@addLine, 'annotation_mistake'})
	end
	if length(handles.apdm_data.sensor) > 1
		head_m = uicontextmenu;
		handles.axes_head.UIContextMenu = head_m;
	% 	uimenu(head_m, 'Label', 'Add Move', 'Callback', {@addMove, handles.axes_head})
		uimenu(head_m, 'Label', 'Add Mistake', 'Callback', {@addLine, 'annotation_mistake'})
	end
	if length(handles.apdm_data.sensor) > 2
		sensor3_m = uicontextmenu;
		handles.axes_sensor3.UIContextMenu = sensor3_m;
	% 	uimenu(sensor3_m, 'Label', 'Add Move', 'Callback', {@addMove, handles.axes_sensor3})
		uimenu(sensor3_m, 'Label', 'Add Mistake', 'Callback', {@addLine, 'annotation_mistake'})
	end
end

% Update handles structure
guidata(hObject, handles);

if isfield(handles, 'restore_data')
	handles = restore_graphic_handles(handles);
end

% Update handles structure
guidata(hObject, handles);
return


% -----------
function handles = create_verg_vel_lines(handles)

if isfield(handles, 'line_lh')
	t = handles.line_lh.XData;
elseif isfield(handles, 'line_rh')
	t = handles.line_rh.XData;
end
lp_filt_freq = str2double(handles.editLPFilt.String);

% vergence velocity - filter the data first
if isfield(handles, 'line_lh')
	lh_filt = lpf(handles.line_lh.YData, 4, lp_filt_freq, handles.eye_data.samp_freq);
end
if isfield(handles, 'line_rh')
	rh_filt = lpf(handles.line_rh.YData, 4, lp_filt_freq, handles.eye_data.samp_freq);
end
if isfield(handles, 'line_rh') && isfield(handles, 'line_lh')
	verg_filt = lh_filt - rh_filt;
	verg_vel = d2pt(verg_filt, 4, handles.eye_data.samp_freq);
	if isfield(handles, 'line_vergence_velocity')
		handles.line_vergence_velocity.YData = verg_vel;
	else
		handles.line_vergence_velocity = line(t, verg_vel, 'Tag', 'line_vergence_velocity', 'Color', 'k', 'Visible', 'off');
	end
end

% lh & rh velocity
if isfield(handles, 'line_lh')
	lh_vel = d2pt(lh_filt, 4, handles.eye_data.samp_freq);
	if isfield(handles, 'line_lh_velocity')
		handles.line_lh_velocity.YData = lh_vel;
	else
		handles.line_lh_velocity = line(t,lh_vel, 'Tag', 'line_lh_velocity', 'Color', 'r', 'LineStyle', '-.', 'Visible', 'off');
		% context menus to add convergence/divergence start times
		eye_m = uicontextmenu;
		handles.line_lh_velocity.UIContextMenu = eye_m;
		uimenu(eye_m, 'Label', 'Add Vergence Start Point', 'Callback', {@add_verge_start, handles.line_lh_velocity});
	end
end

if isfield(handles, 'line_rh')
	rh_vel = d2pt(rh_filt, 4, handles.eye_data.samp_freq);
	if isfield(handles, 'line_rh_velocity')
		handles.line_rh_velocity.YData = rh_vel;
	else
		handles.line_rh_velocity = line(t,rh_vel, 'Tag', 'line_rh_velocity', 'Color', 'g', 'LineStyle', '-.', 'Visible', 'off');
		% context menus to add convergence/divergence start times
		eye_m = uicontextmenu;
		handles.line_rh_velocity.UIContextMenu = eye_m;
		uimenu(eye_m, 'Label', 'Add Vergence Start Point', 'Callback', {@add_verge_start, handles.line_rh_velocity});
	end
end

return

% --------------
function handles = widen_axes(handles)
ax_list = {'axes_eye', 'axes_hand', 'axes_head', 'axes_sensor3'};
for ax = ax_list
	handles.(ax{1}).Position(3) = 0.9;
end

% ---------------------
function handles = add_scrub_lines(handles, init_pos)
% video scrub line in the eye & hand data plots
x_scrub_line = init_pos;
axes(handles.axes_eye)
handles.scrub_line_eye = line( [x_scrub_line, x_scrub_line], handles.axes_eye.YLim, ...
   'Color', 'b', 'linewidth', 2, 'Tag', 'scrub_line_eye');
draggable(handles.scrub_line_eye,'h', @scrubLineMotionFcn)

if isfield(handles, 'apdm_data')
	if ~isempty(handles.apdm_data.sensor)
	   axes(handles.axes_hand)
	   handles.scrub_line_hand = line( [x_scrub_line, x_scrub_line], handles.axes_hand.YLim, ...
		  'Color', 'b', 'linewidth', 2, 'Tag', 'scrub_line_hand');
	   draggable(handles.scrub_line_hand,'h', @scrubLineMotionFcn)
	   handles.linkprop_list(end+1) = linkprop([handles.scrub_line_hand, handles.scrub_line_eye], 'XData');
	end
	if length(handles.apdm_data.sensor) > 1
	   axes(handles.axes_head)
	   handles.scrub_line_head = line( [x_scrub_line, x_scrub_line], handles.axes_head.YLim, ...
		  'Color', 'b', 'linewidth', 2, 'Tag', 'scrub_line_head');
	   draggable(handles.scrub_line_head,'h', @scrubLineMotionFcn)
	   handles.linkprop_list(end+1) = linkprop([handles.scrub_line_head, handles.scrub_line_eye], 'XData');
	end
	if length(handles.apdm_data.sensor) > 2
	   axes(handles.axes_sensor3)
	   handles.scrub_line_sensor3 = line( [x_scrub_line, x_scrub_line], handles.axes_sensor3.YLim, ...
		  'Color', 'b', 'linewidth', 2, 'Tag', 'scrub_line_sensor3');
	   draggable(handles.scrub_line_sensor3,'h', @scrubLineMotionFcn)
	   handles.linkprop_list(end+1) = linkprop([handles.scrub_line_sensor3, handles.scrub_line_eye], 'XData');
	end
end
return

% --- Outputs from this function are returned to the command line.
function varargout = hand_eye_gui_OutputFcn(~, ~, handles)
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
filefilt={'*.m4v;*.mp4;*.mov'};
[fnSave, pnSave] = uigetfile(filefilt,'Choose a Scenelink video file.');
if isequal(fnSave,0) || isequal(pnSave,0)
   disp('no file chosen ... ')
   handles.video_reader = [];
   handles.vid_filename = [];
else
   handles.vid_filename = fullfile(pnSave, fnSave);
   handles.video_reader = VideoReader(handles.vid_filename);
end
% used to syncronize the video start time to the data start time
handles.video_reader.UserData.current_frame_num = 1;

return

% -------------------------------------------------------------
function drawSensorAccelLines(apdm_data, sensor_num)
sensor = apdm_data.sensor{sensor_num};
accel = filterData(apdm_data, sensor_num);

line(apdm_data.time, accel(:,1), 'Tag', ['line_' sensor '_acc_x']);
line(apdm_data.time, accel(:,2), 'Tag', ['line_' sensor '_acc_y'], 'Color', [0.8 0.1 0]);
line(apdm_data.time, accel(:,3), 'Tag', ['line_' sensor '_acc_z'], 'Color', [0.1 0.8 0.2]);
sensor_str = strrep(sensor, '_', ' ');
sensor_str = regexprep(sensor_str,'(\<[a-z])','${upper($1)}');
ylabel(sensor_str)
return


% -------------------------------------------------------------
function drawSensorCombinedVelocityLine(apdm_data, sensor_num)
sensor = apdm_data.sensor{sensor_num};
accel = filterData(apdm_data, sensor_num);

interval = mean(diff(apdm_data.time));
vel = cumtrapz(accel)*interval;

line(apdm_data.time, vel(:,1), 'Tag', ['line_' sensor '_vel_x']);
line(apdm_data.time, vel(:,2), 'Tag', ['line_' sensor '_vel_y'], 'Color', [0.8 0.1 0]);
line(apdm_data.time, vel(:,3), 'Tag', ['line_' sensor '_vel_z'], 'Color', [0.1 0.8 0.2]);

sensor_str = strrep(sensor, '_', ' ');
sensor_str = regexprep(sensor_str,'(\<[a-z])','${upper($1)}');
ylabel(sensor_str)
return

% -------------------------------------------------------------
function drawMagLine(handles, sensor_num)
apdm_data = handles.apdm_data;
sensor = apdm_data.sensor{sensor_num};
mag_rel_earth = apdm_RotateVector(apdm_data.mag{sensor_num}', apdm_data.orient{sensor_num}');

cal_offset = 0;
if isfield(handles, 'head_cal') && isfield(handles.head_cal, 'center')
    cal_offset = handles.head_cal.center;
end
l_r_angle = -atan2(mag_rel_earth(:,2), mag_rel_earth(:,1)) * 180 / pi - cal_offset; 

line(apdm_data.time, l_r_angle, 'Tag', ['line_' sensor '_l_r_angle'], 'Color', [0.2 0.8 0.2], 'Linewidth', 1.5)

line([0 max(apdm_data.time)],[0 0],'color','k')
return

% -------------------------------------------------------------
function drawHeadAngleLine(handles, sensor_num)
apdm_data = handles.apdm_data;
sensor = apdm_data.sensor{sensor_num};
% y vector 
y_vec = [0 1 0];
y_mat = repmat(y_vec, length(apdm_data.orient{sensor_num}),1);
y_in_earth_ref = apdm_RotateVector(y_mat, apdm_data.orient{sensor_num}');

% angle of unit vector in ref X-Y plane (horizontal)
head_horiz_angle = atan2d(y_in_earth_ref(:,1), y_in_earth_ref(:,2));

% only applying calibration offset for now
cal_offset = 0;
if isfield(handles, 'head_cal') && isfield(handles.head_cal, 'center')
    cal_offset = handles.head_cal.center;
	head_horiz_angle = head_horiz_angle - handles.head_cal.center;
end


line(apdm_data.time, head_horiz_angle, 'Tag', ['line_' sensor '_horiz_angle'], 'Color', [0.2 0.8 0.2], 'Linewidth', 1.5)
ylabel('Head Angle (\circ)')
% line([0 max(apdm_data.time)],[0 0],'color','k')
return

% -------------------------------------------------------------
function drawCorrectedVelocityLine(apdm_data, sensor_num)
sensor = apdm_data.sensor{sensor_num};
samp_freq = 1/mean(diff(apdm_data.time));

accel = filterData(apdm_data.accel{sensor_num}, samp_freq)';
% accelEarth = apdm_RotateVector(apdm_data.accel{sensor_num}',apdm_data.orient{sensor_num}');
accelEarth = apdm_RotateVector(accel',apdm_data.orient{sensor_num}');

gyroEarth = apdm_RotateVector(apdm_data.gyro{sensor_num}', apdm_data.orient{sensor_num}');
norm_gyroEarth = zeros(size(gyroEarth,1),1);
for gg = 1:size(gyroEarth,1)
   norm_gyroEarth(gg) = norm(gyroEarth(gg,:));
end


% subtract gravity
gravity_estimate = mean(accelEarth(apdm_data.time<2,3));
accel_no_g = accelEarth;
accel_no_g(:,3) = accel_no_g(:,3) - gravity_estimate;
norm_accel_no_g = zeros(size(accel_no_g,1),1);
for aa = 1:size(accel_no_g,1)
   norm_accel_no_g(aa) = norm(accel_no_g(aa,:));
end


% velocity - integrate
vel = cumsum(accel_no_g,1)/samp_freq;

% when gyro magnitude is < threshold, call that zero velocity -> reset integrated
% velocity to 0
gyro_corrected_vel = zeros(size(vel));
ind = 1;
threshold = 0.1;
while ind < length(norm_gyroEarth)
   if norm_gyroEarth(ind) < threshold % zero vel, look for end of zero vel segment
      next_ind = find(norm_gyroEarth(ind:end) > threshold, 1) + ind - 1; % index of 1st non-zero velocity
%       if ind > 1 && isempty(next_ind)
      if  isempty(next_ind)
         break
	  end
% 	  else
% 		  next_ind = length(norm_gyroEarth);
%       end
      % during this non-zero segment, compute the integral of accel
%       gyro_corrected_vel(ind:next_ind,:) = cumsum(accel_no_g(ind:next_ind,:),1)/samp_freq;
	  
      ind = next_ind;
   else
      % in non-zero segment, look for its end
      next_ind = find(norm_gyroEarth(ind:end) < threshold, 1) + ind - 1; % index of end of non-zero segment
      if isempty(next_ind)
         break
      end
      % during this non-zero segment, compute the integral of accel
      gyro_corrected_vel(ind:next_ind,:) = cumsum(accel_no_g(ind:next_ind,:),1)/samp_freq;
      ind = next_ind;
   end
end

norm_gyro_corrected_vel = zeros(size(gyro_corrected_vel,1),1);
for cc = 1:size(gyro_corrected_vel,1)
   norm_gyro_corrected_vel(cc) = norm(gyro_corrected_vel(cc,:));
end

% line(apdm_data.time, gyro_corrected_vel(:,1), 'Tag', ['line_' sensor '_vel_x']);
% line(apdm_data.time, gyro_corrected_vel(:,2), 'Tag', ['line_' sensor '_vel_y'], 'Color', [0.8 0.1 0]);
% line(apdm_data.time, gyro_corrected_vel(:,3), 'Tag', ['line_' sensor '_vel_z'], 'Color', [0.1 0.8 0.2]);
h_line = line(apdm_data.time, norm_gyro_corrected_vel, 'Tag', ['line_' sensor '_vel_norm'], 'Color', [0.8 0.0 0.7], 'Linewidth', 1.5);

% add context menu to the line
h_menu = uicontextmenu;
h_line.UIContextMenu = h_menu;
uimenu(h_menu, 'Label', 'Add Move', 'Callback', {@addMove, h_line})
uimenu(h_menu, 'Label', 'Scale to Fit', 'Callback', {@scaleData, h_line})

sensor_str = strrep(sensor, '_', ' ');
sensor_str = regexprep(sensor_str,'(\<[a-z])','${upper($1)}');
ylabel(sensor_str)
return

% ------------------------------------------------------------------------------
function scale_norm_gyro_corrected_vel_to_axes(h_ax)
h_line = findobj(h_ax, '-regexp', 'Tag', 'line.*_vel_norm');
assert(~isempty(h_line), 'did not find line.*_vel_norm');
ylims = h_ax.YLim;
max_data = max(h_line.YData);
if max_data < 1, max_data = 1; end % if gyro line is all zeros, scale_factor becomes 0, so line data turns into nans
scale_factor = ylims(2)/max_data;

h_line.YData = h_line.YData * scale_factor;

return

% ------------------------------------------------------------------------------
function add_head_vel_threshold_line(h_ax)
y = [1 1];
xmax = 1;
for cnt = 1:length(h_ax.Children)
	if strcmp(h_ax.Children(cnt).Type, 'line')
		xmax = max([xmax, max(h_ax.Children(cnt).XData)]);
	end
end
h_line = line([0 xmax], y, 'Tag', 'head_vel_threshold_line', 'Color', [0 0 0.8], 'LineWidth', 2);
draggable(h_line, 'v')
% add context menu to the line
h_menu = uicontextmenu;
h_line.UIContextMenu = h_menu;
uimenu(h_menu, 'Label', 'Show Eye Data Below Threshold', 'Callback', {@showEyeDataBelowThresh, h_ax})
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
function handles = resizeAxes(handles)
if ~isfield(handles, 'apdm_data') || ~isfield(handles.apdm_data, 'sensor')
	num_sensors = 0;
else
	num_sensors = length(handles.apdm_data.sensor);
end
switch num_sensors
   case 0
      handles.axes_eye.Position = [0.067 0.24 0.40 0.628];
      handles.axes_eye.XLabel.String = 'Time (sec)';
      handles.axes_hand.Visible = 'Off';
      handles.axes_head.Visible = 'Off';
	  handles.axes_sensor3.Visible = 'Off';
   case 1
      handles.axes_eye.Position = [0.067 0.539 0.40 0.329];
      handles.axes_eye.XTickLabel = {};
      handles.axes_hand.Position = [0.067 0.252 0.40 0.261];
      handles.axes_hand.XLabel.String = 'Time (sec)';
      handles.axes_head.Visible = 'Off';
	  handles.axes_sensor3.Visible = 'Off';
   case 2
      handles.axes_eye.Position = [0.067 0.641 0.40 0.227];
      handles.axes_eye.XTickLabel = {};
      handles.axes_hand.Position = [0.067 0.439 0.40 0.187];
      handles.axes_hand.XTickLabel = {};
      handles.axes_head.Position = [0.067 0.239 0.40 0.187];
      handles.axes_head.XLabel.String = 'Time (sec)';
	  handles.axes_sensor3.Visible = 'Off';
	case 3
      handles.axes_eye.Position = [0.067 0.7 0.40 0.17];
      handles.axes_eye.XTickLabel = {};
      handles.axes_hand.Position = [0.067 0.535 0.40 0.14];
      handles.axes_hand.XTickLabel = {};
      handles.axes_head.Position = [0.067 0.387 0.40 0.14];
	  handles.axes_head.XTickLabel = {};
      handles.axes_sensor3.Position = [0.067 0.24 0.40 0.14];
      handles.axes_sensor3.XLabel.String = 'Time (sec)';
    otherwise
      error('more than 3 sensors of data')
end
return

% -------------------------------------------------------------
function createBox(source,callbackdata, xlims, tag_str)
% if call by create_blinks then the xlims are the blink interval. If xlims
% is empty, then this was called by the exclude data menu and the position
% of the box is at the current cursor postion with a width of 5 s. The
% tag_str is either 'blink' or 'exclude'.

p_color = get_patch_color(tag_str);

handles = guidata(gcf);
axes(handles.axes_eye)
if isempty(xlims)
   cursor_loc = get(handles.axes_eye, 'CurrentPoint');
   cursor_x = cursor_loc(1);
   xlims = [cursor_x cursor_x+5];
end
ylims = get(handles.axes_eye, 'YLim');


if ~isfield(handles, 'dataPatches')
	handles.dataPatches = [];
end
patch_id = unique_id(handles.dataPatches);
handles.dataPatches = [handles.dataPatches, patch_id];

h_patch = patch([xlims(1) xlims(1) xlims(2) xlims(2)], ...
   [ylims(1) ylims(2) ylims(2) ylims(1)], p_color, 'Tag', [tag_str '_id#' num2str(patch_id) '_patch']);
set(h_patch, 'FaceAlpha', 0.5, ...
   'LineStyle', 'none')
createPatchMenu(h_patch);
uistack(h_patch, 'bottom')

% left side of patch
h_left_line = line([xlims(1) xlims(1)], ...
   [ylims(1) ylims(2)], 'Color', 'k', 'Tag', [tag_str  '_id#' num2str(patch_id)  '_l_line']);
h_left_line.UserData = h_patch;

%right side of patch
h_right_line = line([xlims(2) xlims(2)], ...
   [ylims(1) ylims(2)], 'Color', 'k', 'Tag', [tag_str  '_id#' num2str(patch_id) '_r_line']);
h_right_line.UserData = h_patch;

% save lines in patch userdata & make whole patch draggable
h_patch.UserData.h_r_line = h_right_line;
h_patch.UserData.h_l_line = h_left_line;

% matching patch in other axes
if isfield(handles, 'apdm_data')
	if ~isempty(handles.apdm_data.sensor)
	   axes(handles.axes_hand)
	   ylims = get(handles.axes_hand, 'YLim');
	   h_patch2 = patch([xlims(1) xlims(1) xlims(2) xlims(2)], ...
		  [ylims(1) ylims(2) ylims(2) ylims(1)], p_color);
	   set(h_patch2, 'FaceAlpha', 0.5, 'Tag', [tag_str '_id#' num2str(patch_id) '_patch'])
	   uistack(h_patch2, 'bottom')
	   handles.linkprop_list(end+1) = linkprop([h_patch, h_patch2], 'XData');
	end
	if length(handles.apdm_data.sensor) > 1
	   axes(handles.axes_head)
	   ylims = get(handles.axes_head, 'YLim');
	   h_patch2 = patch([xlims(1) xlims(1) xlims(2) xlims(2)], ...
		  [ylims(1) ylims(2) ylims(2) ylims(1)], p_color);
	   set(h_patch2, 'FaceAlpha', 0.5, 'Tag', [tag_str '_id#' num2str(patch_id) '_patch'])
	   uistack(h_patch2, 'bottom')
	   handles.linkprop_list(end+1) = linkprop([h_patch, h_patch2], 'XData');
	end
	if length(handles.apdm_data.sensor) > 2
	   axes(handles.axes_sensor3)
	   ylims = get(handles.axes_sensor3, 'YLim');
	   h_patch2 = patch([xlims(1) xlims(1) xlims(2) xlims(2)], ...
		  [ylims(1) ylims(2) ylims(2) ylims(1)], p_color);
	   set(h_patch2, 'FaceAlpha', 0.5, 'Tag', [tag_str '_id#' num2str(patch_id) '_patch'])
	   uistack(h_patch2, 'bottom')
	   handles.linkprop_list(end+1) = linkprop([h_patch, h_patch2], 'XData');
	end
end

% Update handles structure
guidata(gcf, handles);
return

function p_color = get_patch_color(tag_str)
switch tag_str
	case 'exclude'
		p_color = [0.5 0.5 0.5];
	case 'blink'
		p_color = [0.5 0.2 0.7];
	case 'analysis_1'
		p_color = [0.7 0.2 0.2];
	case 'analysis_2'
		p_color = [0.2 0.7 0.2];
	case 'analysis_3'
		p_color = [0.2 0.2 0.75];
	case 'verg_analysis_seg1'
		p_color = [0.4 0.7 0.4];
	case 'verg_analysis_seg2'
		p_color = [0.4 0.4 0.75];
	otherwise
		p_color = [0.7 0.75 0.2];
end
return


% -------------------------------------------------------------
function addLine(source, callbackdata, line_type)
% function called by menu to add a new line line_type is a string with the
% type (reach, grasp, transfer, mistake)
handles = guidata(gcf);
axes(handles.axes_eye)
cursor_loc = get(handles.axes_eye, 'CurrentPoint');
cursor_x = cursor_loc(1);

handles = addAxesLine(handles, cursor_x, line_type, 'on');

guidata(gcf, handles);

return

% -------------------------------------------------------------
function handles = show_annot_symbols(handles)
if isfield(handles,'apdm_data')
   annot = handles.apdm_data.annot;
   
   for annot_num = 1:length(handles.apdm_data.annot)
      line_type = ['annotation_' annot{annot_num}.msg];
%       handles = addAnnotSymbol(handles, annot{annot_num}.time, line_type, 'on');      
   end
end
return

% -------------------------------------------------------------
function handles = show_annot_lines(handles)
if isfield(handles,'apdm_data') && isfield(handles.apdm_data, 'annot')
   annot = handles.apdm_data.annot;
   
   for annot_num = 1:length(handles.apdm_data.annot)
      line_type = ['annotation_' annot{annot_num}.msg];
      handles = addAxesLine(handles, annot{annot_num}.time, line_type, 'on');      
   end
end
return

% --------------------------------------------------------------
function handles = display_mouse_clicks(handles)
if ~isfield(handles, 'click_data_tbl')
	return
end

ylims = get(handles.axes_eye, 'YLim');

% remove duplicate clicks in the click_data_table.
handles.click_data_tbl(diff(handles.click_data_tbl.abs_click_time) == 0, :) = [];

for click_cnt = 1:height(handles.click_data_tbl)
	% use the abs click time and eye_data start time to display the click time
	if any(strcmp(handles.click_data_tbl.Properties.VariableNames, 'abs_click_time'))
		click_time = (handles.click_data_tbl.abs_click_time(click_cnt) - handles.eye_data.start_times )/1000;

		if click_time >= handles.axes_eye.XLim(1) && click_time <= handles.axes_eye.XLim(2) % only display clicks within the eye data times
			click_coords = parse_click_coords(handles.click_data_tbl.CLICK_COORDINATES(click_cnt));
			if ~isempty(click_coords)
				% line in the eye data axes
				axes(handles.axes_eye)
				h_eye = line([click_time, click_time], ylims, 'Color', 'r', 'LineWidth', 3, ...
					'Tag', ['click_id#' num2str(click_cnt) '_line']);
				uistack(h_eye, 'bottom')
				[hcmenu, ud] = createClickLineMenu(h_eye);
				ud.click_coords = click_coords;
				% symbol on the image
				axes(handles.axes_video_overlay)
				ud.h_click_on_pic = line((ud.click_coords.x-handles.eye_data.h_pix_z) / 30, ...
					-(ud.click_coords.y-handles.eye_data.v_pix_z) / 30, 'Color', 'y', ...
					'MarkerSize', 10, 'Marker', '+', 'Linewidth', 3);
				ud.h_click_on_pic_text = text((ud.click_coords.x-handles.eye_data.h_pix_z) / 30 + 0.5, ...
					-(ud.click_coords.y-handles.eye_data.v_pix_z) / 30 + 0.5, ...
					num2str(click_time,3), ...
					'FontSize', 15, 'FontWeight', 'bold', 'Color', 'y');
				set(h_eye, 'UIContextMenu', hcmenu, 'Userdata', ud)
			end
		end
	end % if abs_click_time is a colum in the click_data_tbl
end
return

% ------------------------------------------------------------
function [hcmenu, ud] = createClickLineMenu(h_line)
hcmenu = uicontextmenu;
ud.hMenuShowClick = uimenu(hcmenu, 'Label', 'Highlight Location', 'Tag', 'menuShowClick', ...
   'Callback', {@menuClickLine_Callback, h_line}, 'Checked', 'off');
ud.hMenuDeleteClick = uimenu(hcmenu, 'Label', 'Delete', 'Tag', 'menuDeleteClick', ...
   'Callback', {@menuClickLine_Callback, h_line}, 'Checked', 'off');
return

function menuClickLine_Callback(source, callbackdata, h_line)
switch source.Tag
	case 'menuShowClick'
		if strcmp(source.Checked, 'on')
			source.Checked = 'off';
			h_line.UserData.h_click_on_pic.Color = 'k';
			h_line.UserData.h_click_on_pic.MarkerSize = 10;
			h_line.UserData.h_click_on_pic_text.Color = 'k';
			h_line.UserData.h_click_on_pic_text.FontSize = 15;
% 			h_line.UserData.h_click_on_pic.Visible = 'off';
		else
			source.Checked = 'on';
			h_line.UserData.h_click_on_pic.Color = 'r';
			h_line.UserData.h_click_on_pic.MarkerSize = 20;
			h_line.UserData.h_click_on_pic_text.Color = 'r';
			h_line.UserData.h_click_on_pic_text.FontSize = 18;
% 			h_line.UserData.h_click_on_pic.Visible = 'on';
		end
	case 'menuDeleteClick'
% 		keyboard
		handles = guidata(gcf);
		row = find_click_tbl_row(handles.click_data_tbl, h_line.UserData.click_coords);
		assert(~isempty(row), 'error finding the row in click_data_tbl for %d, %d', ...
			h_line.UserData.click_coords.x, h_line.UserData.click_coords.y)
% 		handles.click_data_tbl(row,:) = [];
		guidata(gcf, handles)
		delete(h_line.UserData.hMenuShowClick)
		delete(h_line.UserData.hMenuDeleteClick)
		delete(h_line.UserData.h_click_on_pic)
		delete(h_line.UserData.h_click_on_pic_text)	
		delete(h_line)
end
return

function coords = parse_click_coords(cell_str_coords)
if ~iscell(cell_str_coords)
	coords = []; % return empty, not a valid coordinate
	return
end
str_coords = regexp(cell_str_coords{:},'\[(?<x>\d+), (?<y>\d+)\]','names');
if isempty(str_coords)
	coords = []; % return empty, not a valid coordinate
	return
end
coords.x = str2double(str_coords.x);
coords.y = str2double(str_coords.y);
return

function row = find_click_tbl_row(click_data_tbl, click_coords)
row = [];
for row_cnt = 1:height(click_data_tbl)
	coords = parse_click_coords(click_data_tbl.CLICK_COORDINATES(row_cnt));
	if ~isempty(coords) && coords.x == click_coords.x && coords.y == click_coords.y
		row = row_cnt;
		return
	end
end
return

% ----------------------------
function handles = addAxesLine(handles, time, line_type, vis_on_off)
line_color = getLineColor(handles, line_type);


if isfield(handles, 'apdm_data')
	if ~isempty(handles.apdm_data.sensor)

	   axes(handles.axes_hand)
	   ylims = get(handles.axes_hand, 'YLim');
	   h_hand = line([time, time], ylims, 'Color', line_color, 'Tag', line_type, ...
		  'Visible', vis_on_off);
	   uistack(h_hand, 'bottom')
	   [hcmenu, ud] = createLineMenu(h_hand);
	   set(h_hand, 'UIContextMenu', hcmenu, 'UserData', ud);
	end
	if length(handles.apdm_data.sensor) > 1
	   axes(handles.axes_head)
	   ylims = get(handles.axes_head, 'YLim');
	   h_head = line([time, time], ylims, 'Color', line_color, 'Tag',  line_type, ...
		  'Visible', vis_on_off);
	   uistack(h_head, 'bottom')
	   [hcmenu, ud] = createLineMenu(h_head);
	   set(h_head, 'UIContextMenu', hcmenu, 'UserData', ud);
	   handles.linkprop_list(end+1) = linkprop([h_hand, h_head], 'XData');
	end

	if length(handles.apdm_data.sensor) > 2
	   axes(handles.axes_sensor3)
	   ylims = get(handles.axes_sensor3, 'YLim');
	   h_sensor3 = line([time, time], ylims, 'Color', line_color, 'Tag',  line_type, ...
		  'Visible', vis_on_off);
	   uistack(h_head, 'bottom')
	   [hcmenu, ud] = createLineMenu(h_sensor3);
	   set(h_sensor3, 'UIContextMenu', hcmenu, 'UserData', ud);
	   handles.linkprop_list(end+1) = linkprop([h_hand, h_sensor3], 'XData');
	end
else
	axes(handles.axes_eye)
	ylims = get(handles.axes_eye, 'YLim');
	
	h_eye = line([time, time], ylims, 'Color', line_color, 'Tag', line_type, ...
		'Visible', vis_on_off);
	uistack(h_eye, 'bottom')
	
	[hcmenu, ud] = createLineMenu(h_eye);
	ud.line_type = line_type;
	ud.h_all_lines = h_eye;
	set(h_eye, 'UIContextMenu', hcmenu, 'UserData', ud)

end

return

%--------------------------------------
function line_color = getLineColor(handles, type)
line_color = 'y';
h_txt = findobj(handles.figure1, 'Tag', ['txt_' type]);
if ~isempty(h_txt)
   line_color = h_txt.ForegroundColor;
else
   beg_or_end = regexp(type, '(begin)|(end)|(bp)|(start)$', 'match');
   if ~isempty(beg_or_end)
      switch beg_or_end{:}
         case {'begin', 'start'}
            line_color = 'g';
         case 'end'
            line_color = 'r';
		  case 'bp'
			  line_color = 'c';
      end
   end
end
return

% ----------------------------
function createLineColorMenu(hLine)
hcmenu = uicontextmenu;
ud.hMenuShow = uimenu(hcmenu, 'Label', 'Blue', 'Tag', 'menuBlue', ...
   'Callback', {@menuLineColor_Callback, hLine});
ud.hMenuDrag = uimenu(hcmenu, 'Label', 'Green', 'Tag', 'menuGreen', ...
   'Callback', {@menuLineColor_Callback, hLine});
ud.hMenuDrag = uimenu(hcmenu, 'Label', 'Red', 'Tag', 'menuRed', ...
   'Callback', {@menuLineColor_Callback, hLine});
ud.hMenuDrag = uimenu(hcmenu, 'Label', 'Cyan', 'Tag', 'menuCyan', ...
   'Callback', {@menuLineColor_Callback, hLine});
ud.hMenuDrag = uimenu(hcmenu, 'Label', 'Magenta', 'Tag', ...
   'menuMagenta', 'Callback', {@menuLineColor_Callback, hLine});
ud.hMenuDrag = uimenu(hcmenu, 'Label', 'Orange', 'Tag', ...
   'menuOrange', 'Callback', {@menuLineColor_Callback, hLine});
set(hLine, 'UIContextMenu', hcmenu, 'UserData', ud);


function menuLineColor_Callback(source, callbackdata, hLine)
switch source.Tag
   case 'menuBlue'
      hLine.Color = [0 0 0.8];
   case 'menuGreen'
      hLine.Color = [0 0.5 0];
   case 'menuRed'
      hLine.Color = [0.5 0 0];
   case 'menuCyan'
      hLine.Color = [114 214 247]/255;
   case 'menuMagenta'
      hLine.Color = [247 114 238]/255;
   case 'menuOrange'
      hLine.Color = [247 175 114]/255;
end



% -------------------------------------------------------------
function [hcmenu, ud] = createLineMenu(h_line)
hcmenu = uicontextmenu;
ud.hMenuLock = uimenu(hcmenu, 'Label', 'Locked', 'Tag', 'menuLock', ...
   'Callback', {@menuLine_Callback, h_line}, 'Checked', 'on');
ud.hMenuDeleteLine = uimenu(hcmenu, 'Label', 'Delete', 'Tag', 'menuDelete', ...
   'Callback', {@menuLine_Callback, h_line});

% set(h_line, 'UIContextMenu', hcmenu, 'UserData', ud);
return

function menuLine_Callback(source, callbackdata, h_line)
switch source.Tag
   case 'menuLock'
      if strcmp(source.Checked, 'on')
         source.Checked = 'off';
         draggable(h_line,'h');
%          for ind = 1:length(h_line.UserData.h_all_lines),
%             draggable(h_line.UserData.h_all_lines(ind),'h');
%          end
      else
         source.Checked = 'on';
         draggable(h_line, 'off')
%          for ind = 1:length(h_line.UserData.h_all_lines),
%             draggable(h_line.UserData.h_all_lines(ind),'off');
%          end
      end
   case 'menuDelete'
      h_all_lines = findobj('XData', h_line.XData);
      delete(h_all_lines)
end
return


% -------------------------------------------------------------
function createPatchMenu(h_patch)
hcmenu = uicontextmenu;
ud.hMenuLock = uimenu(hcmenu, 'Label', 'Locked', 'Tag', 'menuLock', ...
   'Callback', {@menuPatch_Callback, h_patch}, 'Checked', 'on');
ud.hMenuDelete = uimenu(hcmenu, 'Label', 'Delete', 'Tag', 'menuDelete', ...
   'Callback', {@menuPatch_Callback, h_patch});
set(h_patch, 'UIContextMenu', hcmenu, 'UserData', ud);

function menuPatch_Callback(source, callbackdata, h_patch)
switch source.Tag
   case 'menuLock'
      if strcmp(source.Checked, 'on')
         source.Checked = 'off';
         draggable( h_patch, 'h', @patchMotionFcn)
         draggable(h_patch.UserData.h_l_line,'h', @leftPatchMotionFcn)
         draggable(h_patch.UserData.h_r_line,'h', @rightPatchMotionFcn)
      else
         source.Checked = 'on';
         draggable( h_patch, 'off', @patchMotionFcn)
         draggable(h_patch.UserData.h_l_line,'off', @leftPatchMotionFcn)
         draggable(h_patch.UserData.h_r_line,'off', @rightPatchMotionFcn)
         
      end
	case 'menuDelete'
		% get the tag id #
		idnum_str = regexp(h_patch.Tag, '#\d*', 'match');
		id = str2double(strrep(idnum_str, '#', ''));
		% remove that id from handles.dataPatches
		handles = guidata(gcf);
		handles.dataPatches(handles.dataPatches==id) = [];
		guidata(gcf, handles)

		h_all_patches = findobj(handles.figure1, 'Tag', h_patch.Tag);
      delete(h_patch.UserData.h_l_line)
      delete(h_patch.UserData.h_r_line)
      delete(h_all_patches)
end

% -------------------------------------------------------------
function show_video_frame(handles, time)
if ~isfield(handles, 'video_reader')
	return
end
% axes(handles.axes.video)
samp_freq = handles.eye_data.samp_freq;
min_time = 1/samp_freq;
sample_time = handles.sample_time;
v = handles.video_reader;
if time<min_time, time=min_time; end

% index into eyedata for the time to display
samp_tweak = str2double(handles.samp_tweak.String);
ind = round(time*handles.eye_data.samp_freq)+samp_tweak;
if ind == 0, ind = 1; end

% time in ms for this index plus the start time
abs_t_ms = (ind/samp_freq)*1000 + handles.eye_data.start_times;

% find the corresponding vFramenum
assert(~isempty(handles.eye_data.vframes), 'eye_data.vframes is empty. Was the *.ett file present when running edf2bin?')
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

%  eye pos overlay
display_eye_pos_overlay(handles, time)

% % display eye data & video times in ms
% msg = sprintf('eye data index = %d / samp_freq = %f s + eye start = %d ', ...
%    ind, ind/samp_freq, (ind/samp_freq)*1000 + handles.eye_data.start_times);
% disp(msg)
% msg = sprintf('vid_time = %f; time-offset = %f', time + v.UserData.eye_data_offset, time);
% disp(msg)
return

function display_eye_pos_overlay(handles, time)
min_time = 1/handles.eye_data.samp_freq;

if time<min_time, time=min_time; end

% index into eyedata for the time to display
samp_tweak = str2double(handles.samp_tweak.String);
ind = round(time*handles.eye_data.samp_freq)+samp_tweak;
if ind == 0, ind = 1; end

% right
r_eye = findobj(handles.figure1, 'Tag', 'line_right_eye_overlay');
% samp_tweak = 0;
if isempty(r_eye)
    line(handles.axes_video_overlay, handles.eye_data.rh.pos(ind), ...
       handles.eye_data.rv.pos(ind+samp_tweak), ...
       'Color', 'g', 'Marker', 'o', 'MarkerSize', 20, ... %'MarkerFaceColor', 'g', ...
       'Tag', 'line_right_eye_overlay', 'linewidth',3)
else
   r_eye.XData = handles.eye_data.rh.pos(ind);
   r_eye.YData = handles.eye_data.rv.pos(ind);
end

% left
l_eye = findobj(handles.figure1, 'Tag', 'line_left_eye_overlay');
if isempty(l_eye)
   line(handles.axes_video_overlay, handles.eye_data.lh.pos(ind), ...
      handles.eye_data.lv.pos(ind+samp_tweak), ...
      'Color', 'r', 'Marker', 'o', 'MarkerSize', 20, ... %'MarkerFaceColor', 'r', ...
        'Tag', 'line_left_eye_overlay', 'linewidth',3)
else
   l_eye.XData = handles.eye_data.lh.pos(ind);
   l_eye.YData = handles.eye_data.lv.pos(ind);
end
return

function moveVideoFrame(handles, frames)
samp_freq = handles.eye_data.samp_freq;
min_time = 1/samp_freq;
max_time = min([ length(handles.eye_data.rh.pos) / samp_freq, ...
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

if t < min(h.line_rh.XData)
   t = min(h.line_rh.XData);
end
if t > max(h.line_rh.XData)
   t = max(h.line_rh.XData);
end
adjustAxesForScrubLine(h, t)
if isfield(h, 'video_reader')
	show_video_frame(h, t)
elseif isfield(h, 'im_data')
	show_eye_on_picture(h, t)
end
updateEdTime(h, t)
return

function adjustAxesForScrubLine(handles, time)
% change the x axes limits to keep the line in view
if time < handles.axes_eye.XLim(1)
   handles.axes_eye.XLim(1) = time;
elseif time > handles.axes_eye.XLim(2)
   handles.axes_eye.XLim(2) = time;
end
return

function show_eye_on_picture(handles, time)
% show the red & green circles of the current position
display_eye_pos_overlay(handles, time)
return

% ---------------------------------------------------------------
function leftPatchMotionFcn(h_line)
h_patch = h_line.UserData;
% limit left line to be less than right edge of patch
if h_line.XData(1) >= h_patch.XData(3)
   h_line.XData(1) = h_patch.XData(3);
   h_line.XData(2) = h_patch.XData(3);
end
h_patch.XData(1) = h_line.XData(1);
h_patch.XData(2) = h_line.XData(1);

% ---------------------------------------------------------------
function rightPatchMotionFcn(h_line)
h_patch = h_line.UserData;
% limit right line to be greater than left edge of patch
if h_line.XData(1) <= h_patch.XData(1)
   h_line.XData(1) = h_patch.XData(1);
   h_line.XData(2) = h_patch.XData(1);
end
h_patch.XData(3) = h_line.XData(1);
h_patch.XData(4) = h_line.XData(1);

% ---------------------------------------------------------------
function patchMotionFcn(h_patch)
h_patch.UserData.h_r_line.XData = h_patch.XData(3:4);
h_patch.UserData.h_l_line.XData = h_patch.XData(1:2);

% ---------------------------------------------------------------
function add_verge_start( source, callbackdata, h_line_velocity)
handles = guidata(gcf);
axes(handles.axes_eye)
cursor_loc = get(handles.axes_eye, 'CurrentPoint');
cursor_x = cursor_loc(1);

% from cursor_x, look left on h_line_velocity for a abs value < 5
ind_cursor = find(h_line_velocity.XData>=cursor_x, 1, 'first');
ind_lt_5 = find(abs(h_line_velocity.YData(1:ind_cursor))<5, 1, 'last');

% from this point look right for a abs value >= 5
ind_gt_5 = find(abs(h_line_velocity.YData(ind_lt_5:end))>=5, 1, 'first') + ind_lt_5 - 1;

% at this point add a marker on the velocity line and the vergence line
tmp = regexp(h_line_velocity.Tag, '(lh)|(rh)', 'match');
eye_str  = tmp{1};
x = [h_line_velocity.XData(ind_gt_5) h_line_velocity.XData(ind_gt_5)];
y = [h_line_velocity.YData(ind_gt_5) handles.line_vergence.YData(ind_gt_5)];
h_beg_line = line(x, y, ...
	'Tag', ['vergence_' eye_str '_begin'], 'Color', 'm', 'Marker', 'o', 'MarkerSize', 15);
% menus for the markers to delete
eye_m = uicontextmenu;
h_beg_line.UIContextMenu = eye_m;
uimenu(eye_m, 'Label', 'Delete', 'Callback', {@deleteVergenceMark, h_beg_line}, ...
	'Tag', ['menu_vergence_' eye_str '_begin'])

% add marker for vergence peak velocity
h_verge_vel = findobj(handles.axes_eye, 'Tag', 'line_vergence_velocity');
% from the begin of vergence, look in the next 0.5 sec for the max(abs(velocity))
n_pts_to_look = 1/(h_verge_vel.XData(2)-h_verge_vel.XData(1)) * 0.5;
[max_vel, rel_ind_max_vel] = nanmax(abs(h_verge_vel.YData(ind_gt_5:ind_gt_5+n_pts_to_look)));
if length(rel_ind_max_vel) > 1, rel_ind_max_vel = rel_ind_max_vel(1); end % only use one (first) maximum
ind_max_vel = ind_gt_5 + rel_ind_max_vel - 1;
x = [h_line_velocity.XData(ind_max_vel) h_line_velocity.XData(ind_max_vel)];
y = [h_verge_vel.YData(ind_max_vel) handles.line_vergence.YData(ind_max_vel)];
h_peak_line = line(x, y, ...
	'Tag', ['vergence_peak_velocity'], 'Color', 'k', 'Marker', 's', 'MarkerSize', 12);
h_beg_line.UserData.h_peak_line = h_peak_line;

% add marker for vergence end
% from the peak vergence, look for the (abs(velocity)<5)
n_pts_to_look = 1/(h_verge_vel.XData(2)-h_verge_vel.XData(1)) * 0.5;
rel_ind_below_vel = find(abs(h_verge_vel.YData(ind_max_vel:ind_max_vel+n_pts_to_look)) < 5, 1, 'first');
ind_below_vel = ind_max_vel + rel_ind_below_vel - 1;
x = [h_line_velocity.XData(ind_below_vel) h_line_velocity.XData(ind_below_vel)];
y = [h_verge_vel.YData(ind_below_vel) handles.line_vergence.YData(ind_below_vel)];
h_end_line = line(x, y, ...
	'Tag', ['vergence_' eye_str '_end'], 'Color', 'k', 'Marker', 'p', 'MarkerSize', 12);
h_beg_line.UserData.h_end_line = h_end_line;

guidata(handles.figure1, handles);
return

% ----------------------------------------------------
function deleteVergenceMark(hObject, eventdata, h_verge_mark)
delete(h_verge_mark.UserData.h_peak_line)
delete(h_verge_mark.UserData.h_end_line)
delete(h_verge_mark)
delete(hObject)
return


% --- Executes on button press in pb_export.
function pb_export_Callback(hObject, eventdata, handles)
% hObject    handle to pb_export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% get file name to save
disp('Choose file name to save exported data')
[fnSave, pnSave] = uiputfile({'*.txt'}, 'Choose export data *.txt file ...');
if isequal(fnSave,0) || isequal(pnSave,0)
   disp('no  file chosen ... ')
   return
end
export_filename = fullfile(pnSave, fnSave);

% this takes a while, so displa a wait box
h_wait = waitbar(0, 'Gathering data');

% format data

% eye data
t_eye = handles.line_rh.XData;
rh = handles.eye_data.rh.pos';
lh = handles.eye_data.lh.pos';
if isfield(handles, 'line_vergence') % vergence & no vertical data
	verge_data = handles.line_vergence.YData;
	verg_vel_data = handles.line_vergence_velocity.YData;
	conj_data = handles.line_conjugate.YData;
	verg_target_x_right = handles.line_target_x_right.YData;
	verg_target_x_left = handles.line_target_x_left.YData;
end
if isfield(handles, 'line_rv')
	rv = handles.line_rv.YData;
	rvv = d2pt(rv, 3, handles.eye_data.samp_freq);
else
	rv = nan(size(rh));
	rvv = nan(size(rh))';
end
if isfield(handles, 'line_lv')
	lv = handles.line_lv.YData;
	lvv = d2pt(lv, 3, handles.eye_data.samp_freq);
else
	lv = nan(size(lh));
	lvv = nan(size(lh))';
end


% and velocities
rhv = d2pt(rh, 3, handles.eye_data.samp_freq);
lhv = d2pt(lh, 3, handles.eye_data.samp_freq);
% if isfield(handles, 'line_vergence') % vergence & no vertical data
% 	rvv = rv';
% 	lvv = lv';
% else
% 	rvv = d2pt(rv, 3, handles.eye_data.samp_freq);
% 	lvv = d2pt(lv, 3, handles.eye_data.samp_freq);
% end


out_tbl = table(t_eye', rh', lh', rv', lv', rhv, lhv, rvv, lvv);
out_tbl.Properties.VariableNames = {'t_eye', 'rh', 'lh', 'rv', 'lv', 'rh_vel', 'lh_vel', 'rv_vel', 'lv_vel'};

% pupil data
pupil_mat_file = strrep(handles.bin_filename, '.bin', '_pupil.mat');
if exist(pupil_mat_file, 'file')
	disp('reading in pupil data')
	pupil_data = importdata(pupil_mat_file);
	out_tbl.r_pupil = pupil_data.r;
	out_tbl.l_pupil = pupil_data.l;
else
	disp('No pupil data found. If pupil data is expected, rerun edf2bin(''pupil'')')
end
	

% vergence
if isfield(handles, 'line_vergence') % vergence
	out_tbl.rh_vergence_calibrated = handles.line_rh.YData';
	out_tbl.lh_vergence_calibrated = handles.line_lh.YData';
	out_tbl.rh_vergence_calibrated_velocity = handles.line_rh_velocity.YData';
	out_tbl.lh_vergence_calibrated_velocity = handles.line_lh_velocity.YData';
	out_tbl.vergence = verge_data';
	out_tbl.vergence_velocity = verg_vel_data';
	out_tbl.conjugate = conj_data';
	out_tbl.verg_target_rh_deg = verg_target_x_right';
	out_tbl.verg_target_lh_deg = verg_target_x_left';
end

% for pic diff & reading tasks, add cols for region of interest
h_lines = findobj(handles.axes_video_overlay, '-regexp', 'Tag', 'line.*grid.*');
grid_vals = [];
if ~isempty(h_lines)
	grid_vals = lines_to_grid(h_lines);
	out_tbl.region_of_interest = cell(height(out_tbl), 1);
end

% for smooth pursuit add col if using data below head motion threshold


% saccades
sacc_type_list = {'lh' 'lv' 'rh' 'rv'};
sacc_source_list = {'eyelink', 'findsaccs', 'engbert'};

% handles.eye_data.lh.saccades(2).sacclist.enabled(1:5)


summ_filename = {}; % array to contain filenames if saccade summary file is created  (will
% need to remove blinks and excluded data from the files)
summ_fname_cnt = 0;

%for ss_cnt = 1:length(sacc_source_list)
for st_cnt = 1:length(sacc_type_list)
	st = sacc_type_list{st_cnt};
	for ss_cnt = 1:length(handles.eye_data.(st).saccades)
		sacc_source = handles.eye_data.(st).saccades(ss_cnt).paramtype;
		
		%sacc_type = [sacc_source_list{ss_cnt} '_' sacc_type_list{st_cnt}];
		sacc_type = [sacc_source '_' st];
		
		%sacc_beg_lines = findobj(handles.axes_eye, '-regexp', 'Tag', ['saccade_' sacc_type '.*_begin$']);
		%if ~isempty(sacc_beg_lines)
		sacclist = handles.eye_data.(st).saccades(ss_cnt).sacclist;
		if ~isempty(sacclist.start)
			
			% add column in table for this type of saccade
			out_tbl.([sacc_type '_saccades']) = cell(height(out_tbl), 1);
			out_tbl.([sacc_type '_saccades_labels']) = cell(height(out_tbl), 1);
			
			%  save  ampl & velocity info
			% to a summary file
			sacc_summary_tbl = table();
			sacc_summary_cnt = 0;

			
			%for sac_num = 1:length(sacc_beg_lines)
			for sac_num = 1:length(sacclist.start)
				%waitbar(sac_num/length(sacc_beg_lines), h_wait, ['Getting ' strrep(sacc_type, '_', ' ') ' saccades'])
				waitbar(sac_num/length(sacclist.start), h_wait, ['Getting ' strrep(sacc_type, '_', ' ') ' saccades'])
				%if strcmp(sacc_beg_lines(sac_num).Marker, 'o') % it's enabled 'o', disabled 'x'
				if sacclist.enabled(sac_num)
					%beg_t = sacc_beg_lines(sac_num).XData;
					beg_t = (sacclist.start(sac_num)-handles.eye_data.start_times)/1000;
					%beg_line_tag = sacc_beg_lines(sac_num).Tag;
					%end_line_tag = strrep(beg_line_tag, 'begin', 'end');
					%end_line = findobj(handles.axes_eye, 'Tag', end_line_tag);
					%end_t = end_line.XData;
					end_t = (sacclist.end(sac_num)-handles.eye_data.start_times)/1000;
					% put the line tag into the table
					beg_row = find(out_tbl.t_eye >= beg_t, 1, 'first');
					%out_tbl.([sacc_type '_saccades']){beg_row} = beg_line_tag;
					out_tbl.([sacc_type '_saccades']){beg_row} = [sacc_type '_' num2str(sac_num) '_start'];
					
					end_row = find(out_tbl.t_eye >= end_t, 1, 'first');
					%out_tbl.([sacc_type '_saccades']){end_row} = end_line_tag;
					out_tbl.([sacc_type '_saccades']){end_row} = [sacc_type '_' num2str(sac_num) '_end'];
					
					% find the label menus for this beg_saccade & add a the label if checked
					% this line takes 69% of the time - try to FIX ME
					% by putting label in the eye_data saccade struct
					%h_menus = findobj(handles.axes_eye.Parent, 'Tag',  strrep(sacc_beg_lines(sac_num).Tag, 'saccade', 'menu_saccade'));
					%for m_cnt = 1:length(h_menus)
					%if strcmp(h_menus(m_cnt).Checked, 'on')
					%out_tbl.([sacc_type '_saccades_labels']){beg_row} = h_menus(m_cnt).Label;
					%out_tbl.([sacc_type '_saccades_labels']){end_row} = h_menus(m_cnt).Label;
					%end
					%end
					if isfield(sacclist, 'label')
						out_tbl.([sacc_type '_saccades_labels']){beg_row} = sacclist.label{sac_num};
					end
					
					% if ROI grid
					if ~isempty(grid_vals)
						eye = sacc_type(end-1);
						h_eye = [eye 'h'];
						v_eye = [eye 'v'];
						if isfield(handles, 'grid_file')
							out_tbl.region_of_interest{beg_row} = find_roi_from_file(handles, ...
								out_tbl.(h_eye)(beg_row), out_tbl.(v_eye)(beg_row), beg_t);
							out_tbl.region_of_interest{end_row} = find_roi_from_file(handles, ...
								out_tbl.(h_eye)(end_row), out_tbl.(v_eye)(end_row), end_t);
						else
							out_tbl.region_of_interest{beg_row} = find_default_roi(grid_vals, ...
								out_tbl.(h_eye)(beg_row), out_tbl.(v_eye)(beg_row), beg_t);
							out_tbl.region_of_interest{end_row} = find_default_roi(grid_vals, ...
								out_tbl.(h_eye)(end_row), out_tbl.(v_eye)(end_row), end_t);
						end
					end
					
					% if engbert saccades save engbert ampl & velocity info
					% to a summary file
					if strcmp(sacc_source, 'engbert')
						warning off
						engbert_summary_sacc_file_flg = true;
						sacc_summary_cnt = sacc_summary_cnt + 1;
						sacc_summary_tbl.startTime(sacc_summary_cnt) = beg_t;
						sacc_summary_tbl.endTime(sacc_summary_cnt) = end_t;
						sacc_summary_tbl.hAmpl(sacc_summary_cnt) = sacclist.sacc_horiz_component(sac_num);
						sacc_summary_tbl.vAmpl(sacc_summary_cnt) = sacclist.sacc_vert_component(sac_num);
						sacc_summary_tbl.Ampl(sacc_summary_cnt) = sacclist.sacc_ampl(sac_num);
						sacc_summary_tbl.peakVel(sacc_summary_cnt) = sacclist.peak_vel(sac_num);
						sacc_summary_tbl.hPeakVelComponent(sacc_summary_cnt) = sacclist.peak_vel_horiz_component(sac_num);
						sacc_summary_tbl.vPeakVelComponent(sacc_summary_cnt) = sacclist.peak_vel_vert_component(sac_num);
						
						sacc_summary_tbl.asAmplH(sacc_summary_cnt) = sacclist.as_ampl_horiz(sac_num);
						sacc_summary_tbl.asAmplV(sacc_summary_cnt) = sacclist.as_ampl_vert(sac_num);
						sacc_summary_tbl.asPeakVelH(sacc_summary_cnt) = sacclist.as_peak_vel_horiz(sac_num);
						sacc_summary_tbl.asPeakVelV(sacc_summary_cnt) = sacclist.as_peak_vel_vert(sac_num);
						sacc_summary_tbl.asPeakVelHtime(sacc_summary_cnt) = (sacclist.as_peak_vel_horiz_time(sac_num)-handles.eye_data.start_times/1000);
						sacc_summary_tbl.asPeakVelVtime(sacc_summary_cnt) = (sacclist.as_peak_vel_vert_time(sac_num)-handles.eye_data.start_times/1000);

						sacc_summary_tbl.DriftMeanTime(sacc_summary_cnt) = (sacclist.as_drift_mean_time(sac_num)-handles.eye_data.start_times/1000);
						sacc_summary_tbl.DriftMedianVelHor(sacc_summary_cnt)	 = sacclist.as_median_horiz(sac_num);
						sacc_summary_tbl.DriftMeanVelHor(sacc_summary_cnt)	 = sacclist.as_mean_horiz(sac_num);
						sacc_summary_tbl.DriftVarVelHor(sacc_summary_cnt)	 = sacclist.as_var_horiz(sac_num);
						sacc_summary_tbl.DriftstdVelHor(sacc_summary_cnt)	 = sacclist.as_std_horiz(sac_num);
						sacc_summary_tbl.DriftMedianVelVert(sacc_summary_cnt)	 = sacclist.as_median_vert(sac_num);
						sacc_summary_tbl.DriftMeanVelVert(sacc_summary_cnt)	 = sacclist.as_mean_vert(sac_num);
						sacc_summary_tbl.DriftvarVelVert(sacc_summary_cnt)	 = sacclist.as_var_vert(sac_num);
						sacc_summary_tbl.DriftstdVelVert(sacc_summary_cnt)	 = sacclist.as_std_vert(sac_num);
						sacc_summary_tbl.DriftMedianVel(sacc_summary_cnt)	 = sacclist.as_median_norm_vel(sac_num);
						sacc_summary_tbl.DriftMeanVel(sacc_summary_cnt)	 = sacclist.as_mean_norm_vel(sac_num);
						sacc_summary_tbl.DriftvarVel(sacc_summary_cnt)	 = sacclist.as_var_norm_vel(sac_num);
						sacc_summary_tbl.DriftstdVel(sacc_summary_cnt)	 = sacclist.as_std_norm_vel(sac_num);
						sacc_summary_tbl.DriftMedianPos(sacc_summary_cnt)	 = sacclist.as_median_norm_pos(sac_num);
						sacc_summary_tbl.DriftMeanPos(sacc_summary_cnt)	 = sacclist.as_mean_norm_pos(sac_num);
						sacc_summary_tbl.DriftvarPos(sacc_summary_cnt)	 = sacclist.as_var_norm_pos(sac_num);
						sacc_summary_tbl.DriftstdPos(sacc_summary_cnt)	 = sacclist.as_std_norm_pos(sac_num);


						if ~isempty(grid_vals)
							if ~isempty(out_tbl.region_of_interest{beg_row})
								sacc_summary_tbl.region_of_interest_start(sacc_summary_cnt) = out_tbl.region_of_interest{beg_row};
							end
							if ~isempty(out_tbl.region_of_interest{end_row})
								sacc_summary_tbl.region_of_interest_end(sacc_summary_cnt) = out_tbl.region_of_interest{end_row};
							end
						end
						warning on
					end
					
				end % if enabled
			end % each saccade
			% save the summary table
			if sacc_summary_cnt > 0
				% add 1 more column
				sacc_summary_tbl.asPeakVelCombined = sqrt(sacc_summary_tbl.asPeakVelH .^2 + ...
															sacc_summary_tbl.asPeakVelV .^2);
				summ_fname_cnt = summ_fname_cnt + 1;
				summ_filename{summ_fname_cnt} = strrep(export_filename, '.txt', ['_' sacc_type '.txt']);
				writetable(sacc_summary_tbl, summ_filename{summ_fname_cnt}, 'delimiter', '\t');
			end
		end % if there are saccades of this type for this source
	end % sacc source
end % st_cnt rh, lh, rv, lv
%end % ss_cnt
% fixations
fix_type_list = {'lh' 'lv' 'rh' 'rv'};
for fix_cnt = 1:length(fix_type_list)
	fix_type = fix_type_list{fix_cnt};
	fix_lines = findobj(handles.axes_eye, '-regexp', 'Tag', ['fixation_' fix_type '.*']);
	if ~isempty(fix_lines)
		% add column in table for this type of fixation
		out_tbl.([fix_type '_fixations']) = cell(height(out_tbl), 1);
		for fix_num = 1:length(fix_lines)
			beg_t = min(fix_lines(fix_num).XData);
			beg_line_tag = [fix_lines(fix_num).Tag '_begin'];
			end_t = max(fix_lines(fix_num).XData);
			end_line_tag = strrep(beg_line_tag, 'begin', 'end');
			% put the line tag into the table
			row = find(out_tbl.t_eye >= beg_t, 1, 'first');
			out_tbl.([fix_type '_fixations']){row} = beg_line_tag;
			row = find(out_tbl.t_eye >= end_t, 1, 'first');
			out_tbl.([fix_type '_fixations']){row} = end_line_tag;
		end
	end
end


% sensors
if isfield(handles, 'apdm_data')
if ~isempty(handles.apdm_data.sensor)
	t_sensor = handles.apdm_data.time;
	
	for sens_num = 1:length(handles.apdm_data.sensor)
		sensor = handles.apdm_data.sensor{sens_num};
		accel_x = handles.apdm_data.accel{sens_num}(1,:);
		accel_y = handles.apdm_data.accel{sens_num}(2,:);
		accel_z = handles.apdm_data.accel{sens_num}(3,:);
		gyro_x = handles.apdm_data.gyro{sens_num}(1,:);
		gyro_y = handles.apdm_data.gyro{sens_num}(2,:);
		gyro_z = handles.apdm_data.gyro{sens_num}(3,:);
		mag_x = handles.apdm_data.mag{sens_num}(1,:);
		mag_y = handles.apdm_data.mag{sens_num}(2,:);
		mag_z = handles.apdm_data.mag{sens_num}(3,:);
		orient_1 = handles.apdm_data.orient{sens_num}(1,:);
		orient_2 = handles.apdm_data.orient{sens_num}(2,:);
		orient_3 = handles.apdm_data.orient{sens_num}(3,:);
		orient_4 = handles.apdm_data.orient{sens_num}(4,:);

		[resamp_accel_x, resamp_t] = resample(accel_x, t_sensor, handles.eye_data.samp_freq);
		[resamp_accel_y, resamp_t] = resample(accel_y, t_sensor, handles.eye_data.samp_freq);
		[resamp_accel_z, resamp_t] = resample(accel_z, t_sensor, handles.eye_data.samp_freq);
		[resamp_gyro_x, resamp_t] = resample(gyro_x, t_sensor, handles.eye_data.samp_freq);
		[resamp_gyro_y, resamp_t] = resample(gyro_y, t_sensor, handles.eye_data.samp_freq);
		[resamp_gyro_z, resamp_t] = resample(gyro_z, t_sensor, handles.eye_data.samp_freq);
		[resamp_mag_x, resamp_t] = resample(mag_x, t_sensor, handles.eye_data.samp_freq);
		[resamp_mag_y, resamp_t] = resample(mag_y, t_sensor, handles.eye_data.samp_freq);
		[resamp_mag_z, resamp_t] = resample(mag_z, t_sensor, handles.eye_data.samp_freq);
		[resamp_orient_1, resamp_t] = resample(orient_1, t_sensor, handles.eye_data.samp_freq);
		[resamp_orient_2, resamp_t] = resample(orient_2, t_sensor, handles.eye_data.samp_freq);
		[resamp_orient_3, resamp_t] = resample(orient_3, t_sensor, handles.eye_data.samp_freq);
		[resamp_orient_4, resamp_t] = resample(orient_4, t_sensor, handles.eye_data.samp_freq);
		
		% resamp_t begins at 0, t_eye begins with 0.004. make first values of resamp_t and t_eye match
		resamp_t = resamp_t(2:end);
		resamp_accel_x = resamp_accel_x(2:end);	
		resamp_accel_y = resamp_accel_y(2:end);	
		resamp_accel_z = resamp_accel_z(2:end);	
		resamp_gyro_x = resamp_gyro_x(2:end);	
		resamp_gyro_y = resamp_gyro_y(2:end);	
		resamp_gyro_z = resamp_gyro_z(2:end);	
		resamp_mag_x = resamp_mag_x(2:end);	
		resamp_mag_y = resamp_mag_y(2:end);	
		resamp_mag_z = resamp_mag_z(2:end);	
		resamp_orient_1 = resamp_orient_1(2:end);	
		resamp_orient_2 = resamp_orient_2(2:end);	
		resamp_orient_3 = resamp_orient_3(2:end);	
		resamp_orient_4 = resamp_orient_4(2:end);	
		
		ind_end = length(resamp_t);
		t_diff = resamp_t(end) - t_eye(end);
		if t_diff > eps
			disp('apdm sensor time vector is longer than eye data time vector')
			disp([num2str(t_diff) 's of apdm sensor time will be discarded from the end of the record'])
			ind_end = length(t_eye);
		elseif t_diff < eps
			disp('eye data time vector is longer than apdm sensor time vector')
			ind_end_tbl = height(out_tbl);
			resamp_t(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_accel_x(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_accel_y(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_accel_z(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_gyro_x(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_gyro_y(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_gyro_z(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_mag_x(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_mag_y(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_mag_z(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_orient_1(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_orient_2(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_orient_3(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			resamp_orient_4(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
			ind_end = ind_end_tbl;
		end
		
		% add column for t, accel x, y, & z
		out_tbl.('t_sensors') = resamp_t(1:ind_end);
		out_tbl.([sensor '_accel_x']) = resamp_accel_x(1:ind_end)';
		out_tbl.([sensor '_accel_y']) = resamp_accel_y(1:ind_end)';
		out_tbl.([sensor '_accel_z']) = resamp_accel_z(1:ind_end)';
		out_tbl.([sensor '_gyro_x']) = resamp_gyro_x(1:ind_end)';
		out_tbl.([sensor '_gyro_y']) = resamp_gyro_y(1:ind_end)';
		out_tbl.([sensor '_gyro_z']) = resamp_gyro_z(1:ind_end)';
		out_tbl.([sensor '_mag_x']) = resamp_mag_x(1:ind_end)';
		out_tbl.([sensor '_mag_y']) = resamp_mag_y(1:ind_end)';
		out_tbl.([sensor '_mag_z']) = resamp_mag_z(1:ind_end)';
		out_tbl.([sensor '_orient_1']) = resamp_orient_1(1:ind_end)';
		out_tbl.([sensor '_orient_2']) = resamp_orient_2(1:ind_end)';
		out_tbl.([sensor '_orient_3']) = resamp_orient_3(1:ind_end)';
		out_tbl.([sensor '_orient_4']) = resamp_orient_4(1:ind_end)';
		
		% the string at the end of the axes tag (ie handles.axes_hand or
		% axes_head)
		switch sens_num
			case 1
				axes_str = 'axes_hand';
			case 2
				axes_str = 'axes_head';
			case 3
				axes_str = 'axes_sensor3';
		end
		
		is_head = strcmpi(sensor, 'head'); % output add'l info for the head sensor
		if is_head
			% add column for head angle data
			out_tbl.([sensor '_angle']) = cell(height(out_tbl), 1);
			% 				out_tbl.([sensor '_angle2']) = cell(height(out_tbl), 1);
			% get the angle data line
			h_head_ang_line = findobj(handles.(axes_str), 'Tag', 'line_HEAD_horiz_angle');
			[resamp_head_ang, resamp_t2] = resample(h_head_ang_line.YData, h_head_ang_line.XData, handles.eye_data.samp_freq);
			resamp_head_ang = resamp_head_ang(2:end);
			resamp_t2 = resamp_t2(2:end);
			ind_end = length(resamp_t2);
			t_diff = resamp_t2(end) - t_eye(end);
			if t_diff > eps
				ind_end = length(t_eye);
			elseif t_diff < eps
				ind_end_tbl = height(out_tbl);
				resamp_t2(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
				resamp_head_ang(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
				ind_end = ind_end_tbl;
			end
			out_tbl.([sensor '_angle']) = resamp_head_ang(1:ind_end)';
		end
		
% 		% norm_corrected velocity line data
% 		h_vel_norm_line = findobj(handles.(axes_str), '-regexp', 'Tag', 'line_.*_vel_norm');
% 		out_tbl.([sensor '_gyro_corrected_velocity_norm']) = cell(height(out_tbl), 1);
% 		[resamp_vel_norm, resamp_t2] = resample(h_vel_norm_line.YData, h_vel_norm_line.XData, handles.eye_data.samp_freq);
% 		resamp_vel_norm = resamp_vel_norm(2:end);
% 		resamp_t2 = resamp_t2(2:end);
% 		ind_end = length(resamp_t2);
% 		t_diff = resamp_t2(end) - t_eye(end);
% 		if t_diff > eps
% 			ind_end = length(t_eye);
% 		elseif t_diff < eps
% 			ind_end_tbl = height(out_tbl);
% 			resamp_t2(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
% 			resamp_vel_norm(ind_end+1:ind_end_tbl) = nan(ind_end_tbl-ind_end,1);
% 			ind_end = ind_end_tbl;
% 		end
% 		out_tbl.([sensor '_gyro_corrected_velocity_norm']) = resamp_vel_norm(1:ind_end)';
			
		% moves for each sensor
		move_beg_lines = findobj(handles.(axes_str), '-regexp', 'Tag', 'move_.*_begin$');
		if ~isempty(move_beg_lines)
			% add column for reach for for this sensor
			out_tbl.([sensor '_moves']) = cell(height(out_tbl), 1);
            
			for r_num = 1:length(move_beg_lines)
				beg_t = move_beg_lines(r_num).XData;
				beg_line_tag = move_beg_lines(r_num).Tag;
				end_line_tag = strrep(beg_line_tag, 'begin', 'end');
				end_line = findobj(handles.(axes_str), 'Tag', end_line_tag);
				end_t = end_line.XData;
                % look for breakpoints
                bp_line_tag = strrep(beg_line_tag, 'begin', 'bp');
                bp_lines = findobj(handles.(axes_str), '-regexp', 'Tag', [bp_line_tag '.*']);
                
				% put the line tag into the table
				row = find(out_tbl.t_sensors >= beg_t, 1, 'first');
				out_tbl.([sensor '_moves']){row} = beg_line_tag;
%                 if is_head
%                     ind = find(h_head_ang_line.XData >= beg_t, 1, 'first');
%                     out_tbl.([sensor '_angle2']){row} = h_head_ang_line.YData(ind);
%                 end
				row = find(out_tbl.t_sensors >= end_t, 1, 'first');
				out_tbl.([sensor '_moves']){row} = end_line_tag;
%                 if is_head
%                     ind = find(h_head_ang_line.XData >= end_t, 1, 'first');
%                     out_tbl.([sensor '_angle2']){row} = h_head_ang_line.YData(ind);
%                 end
                if ~isempty(bp_lines)
                    for bp_cnt = 1:length(bp_lines)
                        row = find(out_tbl.t_sensors >= bp_lines(bp_cnt).XData, 1, 'first');
                        out_tbl.([sensor '_moves']){row} = bp_lines(bp_cnt).Tag;
                        if is_head
                            ind = find(h_head_ang_line.XData >= bp_lines(bp_cnt).XData, 1, 'first');
                            out_tbl.([sensor '_angle2']){row} = h_head_ang_line.YData(ind);
                        end
                    end
                end
			end
		end
	end
end % apdm_data.sensor
end % apdm_data

h_stop_evt_line = findobj('Tag', 'Receivedexternaltriggerstopevent');

% marks/annotations
out_tbl.annotation = cell(height(out_tbl),1);
line_list = findobj('-regexp', 'Tag', '^annotation_.*');
xdata = cell2mat(get(line_list, 'XData'));
% mark_list = {'reach', 'mistake'};
%for l_num = 1:length(line_list),
% 	h_lines = findobj('Tag', mark_list{mark_num});
%	xdata = cell2mat(get(h_lines, 'XData'));
for row_cnt = 1:size(xdata,1)
   ind = find(out_tbl.t_sensors >= xdata(row_cnt), 1, 'first');
   % 		out_tbl.annotation(ind) = mark_list(mark_num);
   out_tbl.annotation(ind) = {strrep(line_list(row_cnt).Tag, 'annotation_', '')};
end
%end

% vergence begin
h_verge_marks = findobj(handles.axes_eye, '-regexp', 'Tag', '^vergence_.*begin');
if ~isempty(h_verge_marks)
	out_tbl.vergence_marks = cell(height(out_tbl),1);
	xdata = cell2mat(get(h_verge_marks, 'XData'));
	for row_cnt = 1:size(xdata,1)
		ind = find(out_tbl.t_eye >= xdata(row_cnt), 1, 'first');
		out_tbl.vergence_marks(ind) = {strrep(h_verge_marks(row_cnt).Tag, 'vergence_', '')};
	end
end % vergence marks
% vergence peak vel
h_verge_marks = findobj(handles.axes_eye, 'Tag', 'vergence_peak_velocity');
if ~isempty(h_verge_marks)
	out_tbl.vergence_peak_vel = cell(height(out_tbl),1);
	xdata = cell2mat(get(h_verge_marks, 'XData'));
	for row_cnt = 1:size(xdata,1)
		ind = find(out_tbl.t_eye >= xdata(row_cnt), 1, 'first');
		out_tbl.vergence_peak_vel(ind) = {out_tbl.vergence_velocity(ind)};
	end
end % vergence marks
% vergence end
h_verge_marks = findobj(handles.axes_eye, '-regexp', 'Tag', '^vergence_.*end');
if ~isempty(h_verge_marks)
	out_tbl.vergence_peak_vel = cell(height(out_tbl),1);
	xdata = cell2mat(get(h_verge_marks, 'XData'));
	for row_cnt = 1:size(xdata,1)
		ind = find(out_tbl.t_eye >= xdata(row_cnt), 1, 'first');
		out_tbl.vergence_marks(ind) = {strrep(h_verge_marks(row_cnt).Tag, 'vergence_', '')};
	end
end % vergence marks

% saccade target info
if isfield(handles, 'target_pos') && strcmp(handles.target_pos.type, 'sacc')
	out_tbl.target_on_off = cell(height(out_tbl),1);
	out_tbl.target_x_pos = cell(height(out_tbl),1);
	out_tbl.target_y_pos = cell(height(out_tbl),1);
	out_tbl.target_x_deg = cell(height(out_tbl),1);
	out_tbl.target_y_deg = cell(height(out_tbl),1);
	for t_cnt = 1:length(handles.target_pos.t_start)
		row = find(out_tbl.t_eye >= handles.target_pos.t_start(t_cnt), 1, 'first');
		out_tbl.target_on_off{row} = 'on';
		out_tbl.target_x_pos{row} = handles.target_pos.x_pos(t_cnt);
		out_tbl.target_y_pos{row} = handles.target_pos.y_pos(t_cnt);
		out_tbl.target_x_deg{row} = handles.target_pos.x_deg(t_cnt);
		out_tbl.target_y_deg{row} = handles.target_pos.y_deg(t_cnt);

		if isfield(handles.target_pos, 't_end')
			row = find(out_tbl.t_eye >= handles.target_pos.t_end(t_cnt), 1, 'first');
			out_tbl.target_on_off{row} = 'off';
		end % there is a target end time
		
	end % length of target_pos struct
end % target_pos sacc

% smooth pursuit info
if isfield(handles, 'target_pos') && strcmp(handles.target_pos.type, 'smoothp')

	out_tbl.target_t = handles.target_data.t';
	out_tbl.target_x_deg = handles.target_data.x';
	out_tbl.target_y_deg = handles.target_data.y';
	delta_t = [NaN diff(handles.target_data.t)];
	delta_x = [NaN diff(handles.target_data.x)];
	delta_y = [NaN diff(handles.target_data.y)];
	x_vel = delta_x' ./ delta_t';
	y_vel = delta_y' ./ delta_t';
	% smooth velocity - lp filter at 1Hz
	out_tbl.target_xvel_deg_s = lpf(x_vel, 4, 1, handles.eye_data.samp_freq); 
	out_tbl.target_yvel_deg_s = lpf(y_vel, 4, 1, handles.eye_data.samp_freq);
	
	% head velocity threshold line
	thresh_line = findobj(handles.axes_hand, 'Tag', 'head_vel_threshold_line');
    if ~isempty(thresh_line)
        out_tbl.HEAD_below_threshold = out_tbl.HEAD_gyro_corrected_velocity_norm < thresh_line.YData(1);
    end
	
end % target_pos smoothp


% mouse click info
if isfield(handles, 'click_data_tbl')
	out_tbl.mouse_click_display_begin = cell(height(out_tbl),1);
	disp_time = (handles.click_data_tbl.time_display_begin(1) - handles.eye_data.start_times )/1000;
	row = find(out_tbl.t_eye >= disp_time, 1, 'first');
	if ~any(strcmp(handles.click_data_tbl.Properties.VariableNames, 'abs_click_time'))
		out_tbl.mouse_click_display_begin{row} = 'image displayed';	%
	else
		out_tbl.mouse_click_display_begin{row} = [handles.click_data_tbl.image{1} ' displayed'];
		out_tbl.mouse_click_x_pix = cell(height(out_tbl),1);
		out_tbl.mouse_click_y_pix = cell(height(out_tbl),1);
		out_tbl.mouse_click_x_deg = cell(height(out_tbl),1);
		out_tbl.mouse_click_y_deg = cell(height(out_tbl),1);
	end
	for click_cnt = 1:height(handles.click_data_tbl)
		if ~any(strcmp(handles.click_data_tbl.Properties.VariableNames, 'abs_click_time'))
			break
		end
		if handles.click_data_tbl.abs_click_time(click_cnt) > 0
			click_time = (handles.click_data_tbl.abs_click_time(click_cnt) - handles.eye_data.start_times )/1000;
			click_coords = parse_click_coords(handles.click_data_tbl.CLICK_COORDINATES(click_cnt));
			row = find(out_tbl.t_eye >= click_time, 1, 'first');
			if ~isempty(row)
				out_tbl.mouse_click_x_pix{row} = click_coords.x;
				out_tbl.mouse_click_y_pix{row} = click_coords.y;
				out_tbl.mouse_click_x_deg{row} = (click_coords.x-handles.eye_data.h_pix_z) / 30;
				out_tbl.mouse_click_y_deg{row} = -(click_coords.y-handles.eye_data.v_pix_z) / 30;
			end

	% 		['mouse click: pixel_pos = ' ...
	% 			num2str(click_coords.x) ', ' num2str(click_coords.y) ...
	% 			'; deg = ' num2str((click_coords.x-handles.eye_data.h_pix_z) / 30) ', ' ...
	% 			num2str(-(click_coords.y-handles.eye_data.v_pix_z) / 30)];
		end
	end
end % click data



waitbar(0.5, h_wait, 'Excluding data');

% remove excluded data
h_exclude_patches = findobj(handles.axes_eye, '-regexp', 'Tag', 'exclude_id#\d*_patch');
if ~isempty(h_exclude_patches)
   for seg_num = 1:length(h_exclude_patches)
      % begin exclusion
      excl_beg = h_exclude_patches(seg_num).XData(1);
      % end exclusion
      excl_end = h_exclude_patches(seg_num).XData(4);
      
      ind_excl_beg = find(out_tbl.t_eye >= excl_beg(1), 1, 'first');
      if isempty(ind_excl_beg)
         ind_excl_beg = 1;
      end
      ind_excl_end = find(out_tbl.t_eye >= excl_end(1), 1, 'first');
      if isempty(ind_excl_end)
         ind_excl_end = height(out_tbl);
      end
      % add an annotation
      out_tbl.annotation(ind_excl_beg) = {'begin excluding data'};
      out_tbl.annotation(ind_excl_end) = {'end excluding data'};
      
	  % remove data from out_tbl
      out_tbl = out_tbl([1:ind_excl_beg, ind_excl_end:height(out_tbl)], :);
	  % remove data from summ_filename(summ_fname_cnt)
	  for sf_cnt = 1:summ_fname_cnt
		remove_data_summ_file(summ_filename{sf_cnt}, excl_beg, excl_end);
	  end
   end
end

% remove blinks 
waitbar(0.6, h_wait, 'Removing blinks from data');
h_blinks = findobj(handles.axes_eye, '-regexp', 'Tag', 'blink_id#\d*_patch');
if ~isempty(h_blinks)
	out_tbl.blinks = cell(height(out_tbl), 1);
	for blink_num = 1:length(h_blinks)
		beg_t = min(h_blinks(blink_num).XData);
		beg_txt = ['blink_#' num2str(blink_num) '_begin'];
		end_t = max(h_blinks(blink_num).XData);
		end_txt = ['blink_#' num2str(blink_num) '_end'];
		% put the line tag into the table
		row_beg = find(out_tbl.t_eye >= beg_t, 1, 'first');
		excl_flg = true;
		if ~isempty(row_beg)
			out_tbl.blinks{row_beg} = beg_txt;
		else
			beep
			disp('****** hand_eye_gui line 1535 *******')
			disp('there will be a missing blink beginning in the exported file')
			excl_flg = false;
		end
		row_end = find(out_tbl.t_eye >= end_t, 1, 'first');
		if ~isempty(row_end)
			out_tbl.blinks{row_end} = end_txt;
		else
			beep
			disp('****** hand_eye_gui line 1542 *******')
			disp('there will be a missing blink end in the exported file')
			excl_flg = false;
		end
		if excl_flg
			out_tbl = out_tbl([1:row_beg, row_end:height(out_tbl)], :);
			% remove data from summ_filename(summ_fname_cnt)
			for sf_cnt = 1:summ_fname_cnt
				remove_data_summ_file(summ_filename{sf_cnt}, beg_t, end_t);
			end
		end
	end
end

analyze_out_tbl = table();

% see if analyze data check boxes are checked
if handles.chbx_analyze_1.Value || handles.chbx_analyze_2.Value || handles.chbx_analyze_3.Value
	waitbar(0.75, h_wait, 'Extracting Analysis Data')
	for an_ind = 1:3
		if handles.(['chbx_analyze_' num2str(an_ind)]).Value
% 			disp(an_ind)
			anal_tag = ['analysis_' num2str(an_ind) '_id#\d*_patch'];
			h_analysis_patches = findobj(handles.axes_eye, '-regexp', 'Tag', anal_tag);
			for seg_num = 1:length(h_analysis_patches)
				incl_beg = h_analysis_patches(seg_num).XData(1);
				incl_end = h_analysis_patches(seg_num).XData(4);
				
				ind_incl_beg = find(out_tbl.t_eye >= incl_beg(1), 1, 'first');
				ind_incl_end = find(out_tbl.t_eye >= incl_end(1), 1, 'first');
				
				%annotation
				out_tbl.annotation(ind_incl_beg) = {['begin analysis ' num2str(an_ind) ' data segment ' num2str(seg_num)]};
				out_tbl.annotation(ind_incl_end) = {['end analysis ' num2str(an_ind) ' data segment ' num2str(seg_num)]};
				
				analyze_out_tbl = vertcat(analyze_out_tbl, out_tbl(ind_incl_beg:ind_incl_end,:));
			end
		end
	end
end

if ~isempty(analyze_out_tbl)
	out_tbl = analyze_out_tbl;
end


% write data
waitbar(0.85, h_wait, 'Writing data');
writetable(out_tbl, export_filename, 'delimiter', '\t');

% summarize the file and create a new file named *_summary.txt
waitbar(0.95, h_wait, 'Summarizing data');
summarize_export_file(export_filename)

% close the waitbar
close(h_wait)
return

% -------------------------------------
function grid_vals = lines_to_grid(h_lines)
y_lines = findobj(h_lines, '-regexp', 'Tag', '.*bottom.*');
for cnt = 1:length(y_lines)
	tmp_cell = regexp(y_lines(cnt).Tag, '\d+', 'match');
	num = str2double(tmp_cell{1});
	grid_vals.bottom_row(num) = y_lines(cnt).YData(1);
end

x_lines = findobj(h_lines, '-regexp', 'Tag', '.*left_pic.*');
for cnt = 1:length(x_lines)
	tmp_cell = regexp(x_lines(cnt).Tag, '\d+', 'match');
	num = str2double(tmp_cell{1});
	grid_vals.left_pic_right_col(num) = x_lines(cnt).XData(1);
end

x_lines = findobj(h_lines, '-regexp', 'Tag', '.*right_pic.*');
for cnt = 1:length(x_lines)
	tmp_cell = regexp(x_lines(cnt).Tag, '\d+', 'match');
	num = str2double(tmp_cell{1});
	grid_vals.right_pic_right_col(num) = x_lines(cnt).XData(1);
end

x_lines = findobj(h_lines, '-regexp', 'Tag', 'line_grid_right_col_.*');
for cnt = 1:length(x_lines)
	tmp_cell = regexp(x_lines(cnt).Tag, '\d+', 'match');
	num = str2double(tmp_cell{1});
	grid_vals.right_col(num) = x_lines(cnt).XData(1);
end

return

% -------------------------------------
function roi = find_default_roi(grid_vals, x_eye, y_eye)
roi = [];

grid_row = find(grid_vals.bottom_row <= y_eye, 1);

if isfield(grid_vals, 'left_pic_right_col')
	if x_eye < 0
		left_grid_col = find(grid_vals.left_pic_right_col >= x_eye, 1);
		roi = (grid_row-1) * 5 + 1 + left_grid_col; % top-left = 2, numbered left to right in each row
	else
		right_grid_col = find(grid_vals.right_pic_right_col >= x_eye, 1);
		roi = (grid_row-1) * 5 + 25 + right_grid_col; % top-left = 26, numbered left to right in each row
	end
end
return

% --------------------------
function updateEdTime(h, time)
samp_freq = h.eye_data.samp_freq;
if time<1/samp_freq, time=samp_freq; end
time_str = sprintf('%0.3f', time);
set(h.edTime, 'String', time_str);
return

% -------------------------------
function showFixations(h, r_or_l, h_or_v)           %%% would like to also see VERT
eye_str = [r_or_l(1) h_or_v(1)];
tag_search_str = ['^fixation_' eye_str '.*'];
line_list = findobj(h.figure1,'-regexp', 'Tag', tag_search_str);
if isempty(line_list)
   createFixLines(h, r_or_l, h_or_v);
else
   set(line_list, 'Visible', 'on');
end
% txt_beg_str = ['txt_fixation_' r_or_l '_begin'];
% h.(txt_beg_str).Visible = 'on';
% txt_end_str = ['txt_fixation_' r_or_l '_end'];
% h.(txt_end_str).Visible = 'on';
return

function hideFixations(h, r_or_l, h_or_v)
eye_str = [r_or_l(1) h_or_v(1)];
tag_search_str = ['fixation_' eye_str '.*'];
line_list = findobj(h.figure1,'-regexp', 'Tag', tag_search_str);
if ~isempty(line_list)
   set(line_list, 'Visible', 'off');
end
return

function h = createFixLines(h, r_or_l, h_or_v)
eye_str = [r_or_l(1) h_or_v(1)];
axes(h.axes_eye)
ylims = h.axes_eye.YLim;
start_ms = h.eye_data.start_times;
samp_freq = h.eye_data.samp_freq;
% line_color_beg = getLineColor(h, ['fixation_' r_or_l '_begin']);
% line_color_end = getLineColor(h, ['fixation_' r_or_l '_end']);

for fix_num = 1:length(h.eye_data.(eye_str).fixation.fixlist.start)
   time1 = (h.eye_data.(eye_str).fixation.fixlist.start(fix_num) - start_ms)/1000;
   %line([time1 time1], ylims, 'Tag', ['fixation_' eye_str '_begin'], 'Color', line_color_beg);
   time2 = (h.eye_data.(eye_str).fixation.fixlist.end(fix_num) - start_ms)/1000;
   %line([time2 time2], ylims, 'Tag', ['fixation_' eye_str '_end'], 'Color', line_color_end);
   
   fix_start_ind = round(time1*samp_freq);
   fix_stop_ind  = round(time2*samp_freq);
   tempdata = h.eye_data.(eye_str).pos;
   segment = tempdata(fix_start_ind:fix_stop_ind);
   time3 = maket(segment)+time1;
   line(time3, segment,'Tag', ['fixation_' eye_str '_#' num2str(fix_num)], 'Color','b' , ...
      'Linewidth', 1.5)   
end
return

% -------------------------------
function showSaccades(h, r_or_l, h_or_v)
eye_str = [r_or_l(1) h_or_v(1)];
sacc_source = lower(h.popmenuSaccType.String{h.popmenuSaccType.Value});
tag_search_str = ['^saccade_' sacc_source '_' eye_str '.*'];
line_list = findobj(h.figure1,'-regexp', 'Tag', tag_search_str);
if isempty(line_list)
   createSaccLines(h, r_or_l, h_or_v);
else
   set(line_list, 'Visible', 'on');
   uistack(line_list, 'top')
end
% txt_beg_str = ['txt_saccade_' r_or_l '_begin'];
% h.(txt_beg_str).Visible = 'on';
% txt_end_str = ['txt_saccade_' r_or_l '_end'];
% h.(txt_end_str).Visible = 'on';
return

function hideSaccades(h, r_or_l, h_or_v, sacc_source)
eye_str = [r_or_l(1) h_or_v(1)];
if nargin < 4
	sacc_source = lower(h.popmenuSaccType.String{h.popmenuSaccType.Value});
end
tag_search_str = ['^saccade_' sacc_source '_' eye_str '.*'];
line_list = findobj(h.figure1,'-regexp', 'Tag', tag_search_str);
if ~isempty(line_list)
   set(line_list, 'Visible', 'off');
end
return

function createSaccLines(h, r_or_l, h_or_v)
eye_str = [r_or_l(1) h_or_v(1)];
sacc_source = lower(h.popmenuSaccType.String{h.popmenuSaccType.Value});
if strcmp(sacc_source, 'eyelink')
	sacc_type_str = 'EDF_PARSER';
else
	sacc_type_str = sacc_source;
end
% get sacc type number
found_sacc_type = false;
for s_cnt = 1:length(h.eye_data.(eye_str).saccades)
	if strcmp(h.eye_data.(eye_str).saccades(s_cnt).paramtype, sacc_type_str)
		% have saccades of this type
		sacc_type_num = s_cnt;
		found_sacc_type = true;
	end
end
if ~found_sacc_type % there are no saccades of this type to display
	return
end

% set all the saccades to enabled
num_saccs = length(h.eye_data.(eye_str).saccades(sacc_type_num).sacclist.start);
%h.eye_data.(eye_str).saccades(sacc_type_num).sacclist.enabled=ones(1,num_saccs);


axes(h.axes_eye)

start_ms = h.eye_data.start_times;
beg_line_color = getLineColor(h, ['saccade_' sacc_source '_' eye_str '_begin']);
end_line_color = getLineColor(h, ['saccade_' sacc_source '_' eye_str '_end']);
samp_freq = h.eye_data.samp_freq;

% get eye_data - if there was vergence calibration, then use that data,
% otherwise just the eye.pos data
eye_data = h.eye_data.(eye_str).pos;
if isfield(h.eye_data.(eye_str), 'pos_verge_cal')
	eye_data = h.eye_data.(eye_str).pos_verge_cal;
end



for sacc_num = 1:num_saccs
   % saccade begin
   time1 = (h.eye_data.(eye_str).saccades(sacc_type_num).sacclist.start(sacc_num) - start_ms)/1000; %in seconds
   y = eye_data(round(time1*samp_freq));
   h_beg_line = line( time1, y, 'Tag', ['saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_begin'], ...
      'Color', beg_line_color, 'Marker', 'o', 'MarkerSize', 15);
   eye_m = uicontextmenu;
   h_beg_line.UIContextMenu = eye_m;
   uimenu(eye_m, 'Label', 'Disable Saccade', 'Callback', @disableSaccade, ...
      'Tag', ['menu_saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_begin']);
   uimenu(eye_m, 'Label', 'Pre-Task', 'Callback',  {@labelSaccade, 'PreTask'}, ...
      'Tag', ['menu_saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_begin']);
   uimenu(eye_m, 'Label', 'Task', 'Callback', {@labelSaccade, 'Task'}, ...
      'Tag', ['menu_saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_begin']);
   uimenu(eye_m, 'Label', 'Post-Task', 'Callback',  {@labelSaccade, 'PostTask'}, ...
      'Tag', ['menu_saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_begin']);
  uimenu(eye_m, 'Label', 'Catch-Up', 'Callback',  {@labelSaccade, 'CatchUp'}, ...
      'Tag', ['menu_saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_begin']);
  uimenu(eye_m, 'Label', 'Pure Vergence', 'Callback',  {@labelSaccade, 'PureVergence'}, ...
      'Tag', ['menu_saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_begin']);
   uimenu(eye_m, 'Label', 'Pure Saccade', 'Callback',  {@labelSaccade, 'PureSaccade'}, ...
      'Tag', ['menu_saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_begin']);
  uimenu(eye_m, 'Label', 'Combined Vergence-Saccade', 'Callback',  {@labelSaccade, 'CombinedVergenceSaccade'}, ...
      'Tag', ['menu_saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_begin']);
  
   % saccade end
   time2 = (h.eye_data.(eye_str).saccades(sacc_type_num).sacclist.end(sacc_num) - start_ms)/1000;
   y = eye_data(round(time2*samp_freq));
   h_end_line = line( time2, y, 'Tag', ['saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_end'], ...
      'Color', end_line_color, 'Marker', 'o', 'MarkerSize', 15);
   eye_m2 = uicontextmenu;
   h_end_line.UIContextMenu = eye_m2;
   uimenu(eye_m2, 'Label', 'Add analysis segments', 'Callback', @addAnalSegs, ...
      'Tag', ['menu_saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) '_end']);
   
   % saccade segment
   sac_start_ind = round(time1*samp_freq);
   sac_stop_ind  = round(time2*samp_freq);
%    tempdata = h.eye_data.(eye_str).pos;
   segment = eye_data(sac_start_ind:sac_stop_ind);
   time3 = maket(segment)+time1 - 1/samp_freq;
   line(time3, segment,'Tag', ['saccade_' sacc_source '_' eye_str '_#' num2str(sacc_num) ], 'Color','b' , ...
      'Linewidth', 1.5)
end
guidata(h.figure1, h)
return

function addAnalSegs(source, callbackdata)
handles = guidata(gcf);
axes(handles.axes_eye)

% find the saccade lines for the corresponding tag like
% (saccade_lh_#38_end)
saccade_tag = strrep(source.Tag, 'menu_', '');
saccade_tag_no_beg_end = strrep(saccade_tag, '_end', '');
srch_str = ['^' saccade_tag_no_beg_end '_((begin)|(end))$'];
saccade_beg_end_lines = findobj(handles.axes_eye, '-regexp', 'Tag', srch_str);
% change the marker style 
% set(saccade_beg_end_lines, 'MarkerFaceColor', saccade_beg_end_lines(1).Color)

h_sacc_end = findobj(handles.axes_eye, '-regexp', 'Tag', saccade_tag);
sacc_end_t = h_sacc_end.XData;

% which channel of data

% tmp = regexp(saccade_tag, '(lh)|(rh)|(lv)|(rv)', 'match');
% try
% 	eye_chan = tmp{1};
% catch
% 	fname = ['addAnalSegs eye_chan error ' datestr(now)];
% 	save(fname)
% 	beep
% 	disp('*********')
% 	disp('Error finding disabled saccade line by tag')
% 	disp(['Send the file ' fname ' to Peggy.'])
% 	disp('*********')
% end


box_tag = 'verg_analysis_seg1';
createBox(source,callbackdata, [sacc_end_t+0.02 sacc_end_t+0.12], box_tag)


box_tag = strrep(box_tag, 'seg1', 'seg2');
createBox(source,callbackdata, [sacc_end_t+0.12 sacc_end_t+0.32], box_tag)

handles = guidata(handles.figure1);
guidata(handles.figure1, handles)
return


% function disableSaccade(source, callbackdata)
% handles = guidata(gcf);
% axes(handles.axes_eye)

% % find the saccade lines for the corresponding tag like
% % (saccade_lh_#38_end)
% saccade_tag = strrep(source.Tag, 'menu_', '');
% saccade_tag_no_beg_end = strrep(saccade_tag, '_begin', '');
% srch_str = ['^' saccade_tag_no_beg_end '_((begin)|(end))$'];
% saccade_beg_end_lines = findobj(handles.axes_eye, '-regexp', 'Tag', srch_str);
% % change the marker style 
% set(saccade_beg_end_lines, 'Marker', 'x')

% % and the line in between begin & end markers
% srch_str = ['^' saccade_tag_no_beg_end '$' ];
% saccade_line = findobj(handles.axes_eye, '-regexp', 'Tag', srch_str);
% % change the marker style 
% set(saccade_line, 'LineStyle',':') 

% % set the menu to enable
% set(source, 'Label', 'Enable Saccade', 'Callback', @enableSaccade)

% return

% function enableSaccade(source, callbackdata)
% handles = guidata(gcf);
% axes(handles.axes_eye)

% % find the saccade lines for the corresponding tag like
% % (saccade_lh_#38_end)
% saccade_tag = strrep(source.Tag, 'menu_', '');
% saccade_tag_no_beg_end = strrep(saccade_tag, '_begin', '');
% srch_str = ['^' saccade_tag_no_beg_end '_((begin)|(end))$'];
% saccade_beg_end_lines = findobj(handles.axes_eye, '-regexp', 'Tag', srch_str);
% % change the marker style 
% set(saccade_beg_end_lines, 'Marker', 'o')

% % and the line in between begin & end markers
% srch_str = ['^' saccade_tag_no_beg_end '$' ];
% saccade_line = findobj(handles.axes_eye, '-regexp', 'Tag', srch_str);
% % change the marker style 
% set(saccade_line, 'LineStyle','-') 

% % set the menu to enable
% set(source, 'Label', 'Disable Saccade', 'Callback', @disableSaccade)

% return

% function labelSaccade(source, callbackdata, h_sacc_line, label_str)
% if strcmp(source.Checked, 'off')
% 	h_other = findobj(source.Parent, 'Tag', source.Tag);
% 	set(h_other, 'Checked', 'off')
% 	source.Checked = 'on';
% 	% make the saccade marker filled , 'markerfacecolor', beg_line_color
% % 	h_sacc_line = findobj(source.Parent.Parent, 'Tag', strrep(source.Tag, 'menu_', ''));
% 	h_sacc_line.MarkerFaceColor = h_sacc_line.Color;
% 	h_sacc_line.UserData.label = label_str;
% else
% 	source.Checked = 'off';
% % 	h_sacc_line = findobj(source.Parent.Parent, 'Tag', strrep(source.Tag, 'menu_', ''));
% 	h_sacc_line.MarkerFaceColor = 'none';
% 	h_sacc_line.UserData.label = '';
% end
% return


% -------------------------------
function showBlinks(h)
tag_search_str = 'blink_.*';
patch_list = findobj(h.figure1,'-regexp', 'Tag', tag_search_str);
if isempty(patch_list)
   createBlinkPatches(h);
else
   set(patch_list, 'Visible', 'on'); 
end
return

function hideBlinks(h)
tag_search_str = 'blink_.*';
patch_list = findobj(h.figure1,'-regexp', 'Tag', tag_search_str);
if ~isempty(patch_list)
   set(patch_list, 'Visible', 'off');
end
return

function createBlinkPatches(h)
axes(h.axes_eye)
ylims = h.axes_eye.YLim;
start_ms = h.eye_data.start_times;
samp_freq = h.eye_data.samp_freq;

eye_list = {'rh' 'lh' 'rv' 'lv'};

% go through each eye_list data and combine all blink data together
blinks.start = [];
blinks.end = [];
for elcnt = 1:length(eye_list)
	if isfield(h.eye_data.(eye_list{elcnt}), 'blink')
		if isfield(h.eye_data.(eye_list{elcnt}).blink.blinklist, 'start')
			blinks.start = [blinks.start h.eye_data.(eye_list{elcnt}).blink.blinklist.start(:)'];
			blinks.end = [blinks.end h.eye_data.(eye_list{elcnt}).blink.blinklist.end(:)'];
		end
	end
end

% join the blinks for each data line into a single list of blink segments
% to exlude
blinks = joinBlinks(blinks);

% change absolute ms values to relative to eye_data start time seconds
for cnt = 1:length(blinks.start)
   blinks.start(cnt) = (blinks.start(cnt) - start_ms) / 1000;
   blinks.end(cnt) = (blinks.end(cnt) - start_ms) / 1000;
end

% createBox
for cnt = 1:length(blinks.start)
   createBox([], [], [blinks.start(cnt) blinks.end(cnt)], 'blink')
end
return

function out_blinks = joinBlinks(in_blinks)
% join the blinks for each data line into a single list of blink segments
% loop through in_blinks and move the blink to outblinks, merging any other
% overlapping blinks
out_blink_cnt = 0;
out_blinks.start = [];
out_blinks.end = [];

while ~isempty(in_blinks.start)
   bl_start = in_blinks.start(1);
   bl_end = in_blinks.end(1);
   in_blinks.start(1) = [];
   in_blinks.end(1) = [];
   out_blink_cnt = out_blink_cnt + 1;
   % check if this blink overlaps any others
   
   out_blinks.start(out_blink_cnt) = bl_start;
   out_blinks.end(out_blink_cnt) = bl_end;
   
   overlap_inds = [];
   for ind = 1:length(in_blinks.start)
      
      if  (bl_start >= in_blinks.start(ind) && bl_start <= in_blinks.end(ind)) ... % bl_start is within another blink
            || (bl_end >= in_blinks.start(ind) && bl_end <= in_blinks.end(ind)) ... % bl_end is within another blink
            || (bl_start <= in_blinks.start(ind) && bl_end >= in_blinks.end(ind)) % another blink is fully within this blink
         % start or end overlaps another blink
         overlap_inds = [overlap_inds ind];
         out_blinks.start(out_blink_cnt) = min([out_blinks.start(out_blink_cnt) bl_start in_blinks.start(ind)]);
         out_blinks.end(out_blink_cnt) = max([out_blinks.end(out_blink_cnt) bl_end in_blinks.end(ind)]);
      end
   end
   % remove the overlapping blinks
   in_blinks.start(overlap_inds) = [];
   in_blinks.end(overlap_inds) = [];
   
end
return
% -------------------------------
function scaleData(source, callbackdata, h_line)
% scale this corrected velocity line to show in the axes
h_ax = h_line.Parent;
% get the ydata in the axes x limits
data = h_line.YData(h_line.XData >= h_ax.XLim(1) & h_line.XData <= h_ax.XLim(2));
% scale factor so data is within 90% of the axes y limits
scale = h_ax.YLim(2) * 0.9 / max(data);
h_line.YData = h_line.YData * scale;
return

% -------------------------------
function showEyeDataBelowThresh(source, callbackdata, h_ax)
% h_ax is the head data axes

handles = guidata(gcf);


% get the threshold line and the norm
thresh_line = findobj(h_ax, 'Tag', 'head_vel_threshold_line');
norm_vel_line = findobj(h_ax, 'Tag', 'line_HEAD_vel_norm');

% remove existing eye data below thresh lines
eye_thresh_lines = findobj(handles.axes_eye, '-regexp', 'Tag', 'line_.*_below_thresh');
if ~isempty(eye_thresh_lines)
	delete(eye_thresh_lines)
end

% get eye data lines
eye_lines = findobj(handles.axes_eye, '-regexp', 'Tag', '^line_((l)|(r))((h)|(v))');
if ~isempty(eye_lines)
	t_eye = eye_lines(1).XData;
else
	return
end

% resample the norm_vel_line data so it is the same as the eye data
[resamp_norm_vel, resamp_t] = resample(norm_vel_line.YData, norm_vel_line.XData, handles.eye_data.samp_freq);
% resamp_t begins at 0, t_eye begins at the t = 0.002, resamp_t may be longer than t_eye


[t, ind_norm_vel, ~] = intersect(resamp_t, t_eye); % common time vector
norm_vel = resamp_norm_vel(ind_norm_vel);

for eye_cnt = 1:length(eye_lines)
	tmp_data = eye_lines(eye_cnt).YData;
	tmp_data(norm_vel>thresh_line.YData(1)) = nan; % replace above thresh values with nan
	
	% new line
	line(handles.axes_eye, t, tmp_data, 'Tag', [eye_lines(eye_cnt).Tag '_below_thresh'], ...
		'Color', eye_lines(eye_cnt).Color, 'LineWidth', eye_lines(eye_cnt).LineWidth*3)
end

return

% -------------------------------
function addMove(source, callbackdata, h_line)
handles = guidata(gcf);
axes(h_line.Parent)
cursor_loc = get(h_line.Parent, 'CurrentPoint');
cursor_x = cursor_loc(1);

% type of reach - single or triple 
r_type = 1; % single 
if handles.rbTriple.Value
	r_type = 3; % triple
end
	
[move_beg, move_end] = detectReach(h_line, cursor_x, r_type);
% if r_type > than 1 hump, find and add the points at the minima between the humps
reach_bps = findReachBreakPoints(h_line, move_beg, move_end, r_type);
% returned: reach_bps = [] if move_beg or end = [], or if r_type < 2 i.e. no bps to find


if ~isempty(move_beg) && ~isempty(move_end)
	handles = createReachLine(handles, h_line.Parent, move_beg, move_end, reach_bps);
end

guidata(gcf, handles)
return

function [move_beg, move_end] = detectReach(h_line, approx_time, num_humps)
% near the approx time, find the non-zero velocity segment
move_beg = []; % if not found, then return empty values
move_end = [];

% examine the gyro corrected norm velocity line data
norm_vel_line = h_line;
time_data = norm_vel_line.XData;
vel_data = norm_vel_line.YData;

approx_ind = find(time_data >= approx_time, 1, 'first');

% find the last vel=0 point before the approx time
move_beg_ind = find(vel_data(1:approx_ind) < eps, 1, 'last'); 
if ~isempty(move_beg_ind)
   move_beg = time_data(move_beg_ind);
end

% and the first vel=0 point after the approx time
move_end_ind = approx_ind-1 + find(vel_data(approx_ind:end) < eps, 1, 'first'); 
if ~isempty(move_end_ind)
   move_end = time_data(move_end_ind);
end
% make sure begin and end are not the same, if they are, then it is not a
% reach
if move_end - move_beg < eps
	msg = sprintf('no reach detected at t = %f', approx_time);
	disp(msg)
	move_beg = []; 
	move_end = [];
	return
end

% try to enforce the proper number of humps in the move velocity line
found_hump_num = find_num_humps(time_data(move_beg_ind:move_end_ind), vel_data(move_beg_ind:move_end_ind));
if found_hump_num < num_humps
	% increase length of move to find more humps
	hump_increment = (move_end_ind - move_beg_ind+1) ./ found_hump_num .* (num_humps - found_hump_num);
	tmp_beg_ind = max(round(move_beg_ind - hump_increment*1.5), 1);
	tmp_end_ind = min(round(move_end_ind + hump_increment*1.5), length(vel_data));
	[approx_move_beg, approx_move_end] = find_data_with_n_humps(time_data(tmp_beg_ind:tmp_end_ind), ...
		vel_data(tmp_beg_ind:tmp_end_ind), num_humps, approx_time);
	approx_beg_ind = find(time_data >= approx_move_beg, 1, 'first');
	approx_end_ind = find(time_data >= approx_move_end, 1, 'first');
	move_beg_ind = find(vel_data(approx_beg_ind:approx_end_ind) > eps, 1, 'first') + approx_beg_ind-1; 
	if ~isempty(move_beg_ind)
		move_beg = time_data(move_beg_ind);
	end
	move_end_ind = find(vel_data(approx_end_ind:end) < eps, 1, 'first') + approx_end_ind-1; 
	if ~isempty(move_end_ind)
		move_end = time_data(move_end_ind);
	end
elseif found_hump_num > num_humps
	% decrease the move length
	[move_beg, move_end] = find_data_with_n_humps(time_data(move_beg_ind:move_end_ind), ...
		vel_data(move_beg_ind:move_end_ind), num_humps, approx_time);
end


return

function reach_bps = findReachBreakPoints(h_line, move_beg, move_end, num_humps)
% find the minima between the num_humps maxima in the h_line between
% move_beg & move_end times
reach_bps = [];
if isempty(move_beg) || isempty(move_end), return, end
if num_humps < 2, return, end

% h_line is the normalized velocity data line
time_data = h_line.XData;
vel_data = h_line.YData;

reach_time_data = time_data(time_data>=move_beg & time_data<=move_end);
reach_vel_data = vel_data(time_data>=move_beg & time_data<=move_end);

% find extrema, if there are more than num_humps maxima, smooth the data,
% and find again. Keep smoothing and finding until there are num_humps
% maxima
[xmax,imax,xmin,imin]=extrema(reach_vel_data);
if length(xmax) > num_humps
	smoothing_pts = 5;	
	while length(xmax) > num_humps && smoothing_pts < length(reach_vel_data)
		smooth_data = smooth(reach_vel_data, smoothing_pts, 'sgolay');
		[xmax,imax,xmin,imin]=extrema(smooth_data);
		smoothing_pts = smoothing_pts + 1;
	end
end

% find the minima in between the maxima from the unsmoothed data 
imax = sort(imax);	% extrema returns values in sorted order of the max value, not index order
min_vals = nan(1, length(imax)-1);
min_inds = nan(1, length(imax)-1);
for min_cnt = 1:length(imax)-1
	[val, ind] = min(reach_vel_data(imax(min_cnt):imax(min_cnt+1)));
	min_vals(min_cnt) = val;
	min_inds(min_cnt) = ind + imax(min_cnt) - 1;
end
% use indices to return the times
reach_bps = reach_time_data(min_inds);
return

function handles = createReachLine(handles, h_axes, move_beg, move_end, move_bps)
beg_line_color = getLineColor(handles, 'move_begin');
end_line_color = getLineColor(handles, 'move_end');
bp_line_color = getLineColor(handles, 'move_bp');

% handles contains the number of reaches turned into lines, so they can be
% uniquely tagged
if ~isfield(handles, 'move_id_list')
   handles.move_id_list = [];
end
move_id = unique_id(handles.move_id_list);
handles.move_id_list = [handles.move_id_list move_id];

% line overlays the gyro corrected norm velocity line
norm_vel_line = findobj(h_axes, '-regexp', 'Tag', 'line_.*_vel_norm');
time_data = norm_vel_line.XData;
vel_data = norm_vel_line.YData;

% marker at begin
% y = vel_data(time_data == move_beg);
y = get_y_val(time_data, vel_data, move_beg);
h_line=line( move_beg, y, 'Tag', ['move_#' num2str(move_id) '_begin'], 'Color', beg_line_color, ...
   'Marker', 'o', 'Markersize', 12, 'MarkerFaceColor', beg_line_color);
draggable(h_line, @reachLineMotionFcn)

% marker at end
%y = vel_data(time_data == move_end);
y = get_y_val(time_data, vel_data, move_end);
h_line = line( move_end, y, 'Tag', ['move_#' num2str(move_id) '_end'], 'Color', end_line_color, ...
   'Marker', 'o', 'Markersize', 12, 'MarkerFaceColor', end_line_color);
draggable(h_line, @reachLineMotionFcn)

% markers for breakpoints
if ~isempty(move_bps)
	for bp_cnt = 1:length(move_bps)
		%y = vel_data(time_data == move_bps(bp_cnt));
		y = get_y_val(time_data, vel_data, move_bps(bp_cnt));
		h_line = line( move_bps(bp_cnt), y, 'Tag', ['move_#' num2str(move_id) '_bp' num2str(bp_cnt)], ...
			'Color', bp_line_color, 'Marker', 'o', 'Markersize', 12, 'MarkerFaceColor', bp_line_color);
		draggable(h_line, @reachLineMotionFcn)
	end
end
	
% interval line
y = vel_data(time_data > move_beg & time_data < move_end);
t = time_data(time_data > move_beg & time_data < move_end);
h_line = line(t, y, 'Color', 'b', 'Linewidth', 2, 'Tag', ['move_#' num2str(move_id) '_interval']);
% menu item to delete it
line_m = uicontextmenu;
h_line.UIContextMenu = line_m;
uimenu(line_m, 'Label', 'Delete', 'Callback', @removeMove, 'Tag', ['menu_move_#' num2str(move_id)])

return

function removeMove(source_menu, callbackdata)
% get the tag id #
id = str2double(strrep(source_menu.Tag, 'menu_move_#', ''));
% remove that id from handles.move_id_list
handles = guidata(gcf);
handles.move_id_list(handles.move_id_list==id) = [];
guidata(gcf, handles)

% delete the line and its menu
move_line_tag_str = ['move_#' num2str(id)];
h_lines = findobj(gcf, '-regexp', 'Tag', [move_line_tag_str '.*']);
delete(h_lines)
return

function reachLineMotionFcn(h_line)
beg_or_end = regexp(h_line.Tag, '(begin)|(end)|(bp)', 'match');
move_num = regexp(h_line.Tag, '\d', 'match');

h_line_interval = findobj(h_line.Parent, 'Tag', ['move_#' num2str(move_num{:}) '_interval']);

norm_vel_line = findobj(h_line.Parent, '-regexp', 'Tag', 'line_.*_vel_norm');
time_data = norm_vel_line.XData;
vel_data = norm_vel_line.YData;

% h_line y data must stay on the norm_vel_line
t_ind = find(time_data >= h_line.XData, 1, 'first'); % time index of the moved begin or end line
if isempty(t_ind)
   if h_line.XData < time_data(1)
      t_ind = 1;
   elseif h_line.XData > time_data(end)
      t_ind = length(time_data);
   end
end
h_line.YData = vel_data(t_ind);
   
% shrink or grow the inteval line as needed
switch beg_or_end{:}
   case 'begin'     
      if time_data(t_ind) < h_line_interval.XData(1)
         % add points to the beginning
         add_inds = find(time_data > time_data(t_ind) & time_data < h_line_interval.XData(1));
         set(h_line_interval, 'XData', [time_data(add_inds) h_line_interval.XData], ...
            'YData', [vel_data(add_inds) h_line_interval.YData]);
      else
         % take points away from beginning
         shorter_line_inds = find(h_line_interval.XData > time_data(t_ind));
         if ~isempty(shorter_line_inds)
            set(h_line_interval, 'XData', h_line_interval.XData(shorter_line_inds), ...
               'YData', h_line_interval.YData(shorter_line_inds));
         else
            % don't allow the line to move beyond the end
            h_line.XData = h_line_interval.XData(end);
            h_line.YData = h_line_interval.YData(end);
         end
      end
   case 'end'
      if time_data(t_ind) > h_line_interval.XData(end)
         % add points to the end
         add_inds = find(time_data > h_line_interval.XData(end) & time_data < time_data(t_ind));
         set(h_line_interval, 'XData', [ h_line_interval.XData time_data(add_inds)], ...
            'YData', [h_line_interval.YData vel_data(add_inds) ]);
      else
         % take points away from end
         shorter_line_inds = find(h_line_interval.XData < time_data(t_ind));
         if ~isempty(shorter_line_inds)
            set(h_line_interval, 'XData', h_line_interval.XData(shorter_line_inds), ...
               'YData', h_line_interval.YData(shorter_line_inds));
         else
            % don't allow the line to move beyond the beginning
            h_line.XData = h_line_interval.XData(1);
            h_line.YData = h_line_interval.YData(1);
         end
      end
      
end

return

% -------------------------------
function showAnnotations(h)
line_list = findobj(h.figure1,'-regexp', 'Tag', 'annotation_.*');
if ~isempty(line_list)
   set(line_list, 'Visible', 'on');
end
return

function hideAnnotations(h)
line_list = findobj(h.figure1,'-regexp', 'Tag', 'annotation_.*');
if ~isempty(line_list)
   set(line_list, 'Visible', 'off');
end
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

if get(hObject,'Value') % returns toggle state of tbFixations
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

if get(hObject,'Value') % returns toggle state of tbFixations
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
if get(hObject,'Value') % returns toggle state of tbFixations
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
if get(hObject,'Value') % returns toggle state of tbFixations
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

if get(hObject,'Value') % returns toggle state of tbSaccades
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

if get(hObject,'Value') % returns toggle state of tbFixations
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

% --- Executes on button press in tbShowRH.
function tbShowRH_Callback(hObject, eventdata, handles)
% hObject    handle to tbShowRH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state of tbShowRH
   set(handles.line_rh, 'Visible', 'on')
else
   set(handles.line_rh, 'Visible', 'off')
end
return

% --- Executes on button press in tbShowLH.
function tbShowLH_Callback(hObject, eventdata, handles)
% hObject    handle to tbShowLH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state of tbShowLH
   set(handles.line_lh, 'Visible', 'on')
else
   set(handles.line_lh, 'Visible', 'off')
end
return


% --- Executes on button press in tbShowRV.
function tbShowRV_Callback(hObject, eventdata, handles)
% hObject    handle to tbShowRV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') % returns toggle state of tbShowRV
   set(handles.line_rv, 'Visible', 'on')
else
   set(handles.line_rv, 'Visible', 'off')
end
return


% --- Executes on button press in tbShowLV.
function tbShowLV_Callback(hObject, eventdata, handles)
% hObject    handle to tbShowLV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value') % returns toggle state of tbShowLV
   set(handles.line_lv, 'Visible', 'on')
else
   set(handles.line_lv, 'Visible', 'off')
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
h_scrub_line = findobj(handles.axes_eye, 'Tag', 'scrub_line_eye');
incr = 0.1 * playback_speed;
while strcmp(hObject.String, 'Pause') && h_scrub_line.XData(1) <= max(handles.line_rh.XData)
   h_scrub_line.XData = h_scrub_line.XData + incr;
   scrubLineMotionFcn(h_scrub_line)
   drawnow
end

% stop if we reach the end of the data
if h_scrub_line.XData >= max(handles.line_rh.XData)
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
if isequal(filename, 0) || isequal(pathname, 0)
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
state.tbAnnotations.Value = handles.tbAnnotations.Value;
state.tbExcludeBlinks.Value = handles.tbExcludeBlinks.Value;
state.tbSaccadesLeftVert.Value = handles.tbSaccadesLeftVert.Value;
state.tbSaccadesRightVert.Value = handles.tbSaccadesRightVert.Value;
state.tbSaccadesLeftHoriz.Value = handles.tbSaccadesLeftHoriz.Value;
state.tbSaccadesRightHoriz.Value = handles.tbSaccadesRightHoriz.Value;
state.tbFixationsLeftVert.Value = handles.tbFixationsLeftVert.Value;
state.tbFixationsRightVert.Value = handles.tbFixationsRightVert.Value;
state.tbFixationsLeftHoriz.Value = handles.tbFixationsLeftHoriz.Value;
state.tbFixationsRightHoriz.Value = handles.tbFixationsRightHoriz.Value;
state.tbShowRH.Value = handles.tbShowRH.Value;
state.tbShowLH.Value = handles.tbShowLH.Value;
state.tbShowRV.Value = handles.tbShowRV.Value;
state.tbShowLV.Value = handles.tbShowLV.Value;
state.tbTargetV.Value = handles.tbTargetV.Value;
state.tbTargetH.Value = handles.tbTargetH.Value;
state.edTime.String = handles.edTime.String;
state.rbSingle.Value = handles.rbSingle.Value;
state.rbTriple.Value = handles.rbTriple.Value;
state.bin_filename = handles.bin_filename;
if isfield(handles, 'hdf_filename')
	state.hdf_filename = handles.hdf_filename;
end
if isfield(handles, 'vid_filename')
	state.vid_filename = handles.vid_filename;
end
state.eye_data = handles.eye_data;
if isfield(handles, 'apdm_data')
	state.apdm_data = handles.apdm_data;
end

% axes limits

% video scrub line
if isfield(handles, 'scrub_line_eye')
	state.scrub_line_eye.XData = handles.scrub_line_eye.XData;
end

% saccades
sacc_menus = findobj(handles.figure1, '-regexp', 'Tag', 'menu_sacc.*begin'); % beginning saccade menus contain if they are disabled or labeled
state.sacc_disabled = [];
state.sacc_labels = [];
for m_cnt = 1:length(sacc_menus)
	tag_split = regexp(sacc_menus(m_cnt).Tag, '_','split');
	sacctype = tag_split{3};
	if strcmp(sacc_menus(m_cnt).Label, 'Enable Saccade')
		% this saccade is disabled
		% get the saccade's time from the similarly tagged saccade line
		hs_line = findobj(handles.axes_eye, 'Tag', strrep(sacc_menus(m_cnt).Tag, 'menu_', ''));
		state.sacc_disabled(end+1).type = sacctype;
		state.sacc_disabled(end).xdata = hs_line.XData;	% the saccade time
	elseif strcmp(sacc_menus(m_cnt).Label, 'Disable Saccadde')
		% do nothing
	else % labels other than enable/disable
		if strcmp(sacc_menus(m_cnt).Checked, 'on')
			hs_line = findobj(handles.axes_eye, 'Tag', strrep(sacc_menus(m_cnt).Tag, 'menu_', ''));
			state.sacc_labels(end+1).type = sacctype;
			state.sacc_labels(end).label = sacc_menus(m_cnt).Label;
			state.sacc_labels(end).xdata = hs_line.XData;
		end
	end
end

% blinks
blink_patches = findobj(handles.axes_eye, '-regexp', 'Tag', 'blink_.*_patch');
state.blinks = cell(length(blink_patches));
for b_cnt = 1:length(blink_patches)
	state.blinks{b_cnt} = blink_patches(b_cnt).Vertices([1 3]);
end
% annotations 
state.annots = [];
if isfield(handles, 'axes_hand')
	annots = findobj(handles.axes_hand, 'Tag', 'annotation_mistake');
	for a_cnt = 1:length(annots)
		state.annots(a_cnt).xdata = annots(a_cnt).XData(1);
		state.annots(a_cnt).txt = annots(a_cnt).Tag;
	end
end
% exclude patches
exclude_patches = findobj(handles.axes_eye, '-regexp', 'Tag', 'exclude_.*_patch');
state.excludes = cell(length(exclude_patches));
for b_cnt = 1:length(exclude_patches)
	state.excludes{b_cnt} = exclude_patches(b_cnt).Vertices([1 3]);
end
% analyze patches
analysis_patches = findobj(handles.axes_eye, '-regexp', 'Tag', 'analysis_.*_patch');
state.analysis = [];
for b_cnt = 1:length(analysis_patches)
	state.analysis(b_cnt).type = regexp(analysis_patches(b_cnt).Tag, '_\d','match');
	state.analysis(b_cnt).Vertices = analysis_patches(b_cnt).Vertices([1 3]);
end
% moves/reaches
reaches = findobj(handles.figure1, '-regexp', 'Tag', 'move_#.*_begin');
state.reaches = [];
for r_cnt = 1:length(reaches)
	% get end and bp reaches with this tag id#
	tag_split = regexp(reaches(r_cnt).Tag, '_', 'split'); % returns cell array like: 'move'    '#2'    'begin'
	end_reach = findobj(handles.figure1, '-regexp', 'Tag', ['move_' tag_split{2} '_end']);
	bp_reaches = findobj(handles.figure1, '-regexp', 'Tag', ['move_' tag_split{2} '_bp\d']);
	state.reaches(r_cnt).axes_tag = reaches(r_cnt).Parent.Tag;
	state.reaches(r_cnt).begin = reaches(r_cnt).XData;
	state.reaches(r_cnt).end = end_reach.XData;
	state.reaches(r_cnt).bps = [];
	for bp_cnt = 1:length(bp_reaches)
		state.reaches(r_cnt).bps(end+1) = bp_reaches(bp_cnt).XData;
	end
end

% target data
if isfield(handles, 'target_data')
	state.target_data = handles.target_data;
end
if isfield(handles, 'target_pos')
	state.target_pos = handles.target_pos;
end

% mouse click data
if isfield(handles, 'click_data_tbl')
	state.click_data_tbl = handles.click_data_tbl;
end
if isfield(handles, 'click_filename')
	state.click_filename = handles.click_filename;
end
if isfield(handles, 'im_data')
	state.im_data = handles.im_data;
end

save(fullfile(pathname,filename), 'state')
return


% --- Executes on button press in pbLoad.
function pbLoad_Callback(hObject, eventdata, handles)
% hObject    handle to pbLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = read_restore_state(handles);
guidata(handles.figure1, handles)

function handles = read_restore_state(handles, varargin)
% optional input - filename, then the dialog box asking for the filename
% will not be displayed

if nargin > 1
    filename = varargin{1};
else
    [filename, pathname] = uigetfile('*.mat', 'Load GUI Data');
    if isequal(filename, 0) || isequal(pathname, 0)
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
handles.tbShowRH.Value = state.tbShowRH.Value;
handles.tbShowLH.Value = state.tbShowLH.Value;
handles.tbShowRV.Value = state.tbShowRV.Value;
handles.tbShowLV.Value = state.tbShowLV.Value;
handles.tbTargetH.Value = state.tbTargetH.Value;
handles.tbTargetV.Value = state.tbTargetV.Value;
handles.edTime.String = state.edTime.String;
handles.rbSingle.Value = state.rbSingle.Value;
handles.rbTriple.Value = state.rbTriple.Value;
handles.bin_filename = state.bin_filename;
if isfield(state, 'hdf_filename')
	handles.hdf_filename = state.hdf_filename;
end
if isfield(state, 'vid_filename')
	handles.vid_filename = state.vid_filename;
end
handles.eye_data = state.eye_data;
if isfield(state, 'apdm_data')
	handles.apdm_data = state.apdm_data;
end
if isfield(state, 'scrub_line_eye')
	handles.restore_data.scrub_line_eye.XData = state.scrub_line_eye.XData;
end
handles.restore_data.sacc_disabled = state.sacc_disabled;
handles.restore_data.sacc_labels = state.sacc_labels;
handles.restore_data.blinks = state.blinks;
handles.restore_data.annots = state.annots;
handles.restore_data.excludes = state.excludes;
handles.restore_data.analysis = state.analysis;
handles.restore_data.reaches = state.reaches;

if isfield(state, 'target_data')
	handles.restore_data.target_data = state.target_data;
end
if isfield(state, 'target_pos')
	handles.restore_data.target_pos = state.target_pos;
end

if isfield(state, 'click_data_tbl')
	handles.restore_data.click_data_tbl = state.click_data_tbl;
end
if isfield(state, 'click_filename')
	handles.restore_data.click_filename = state.click_filename;
end
if isfield(state, 'im_data')
	handles.restore_data.im_data = state.im_data;
end
return

function handles = restore_graphic_handles(handles)
% eye lines visibility
if ~handles.tbShowRH.Value, handles.line_rh.Visible = 'off'; end
if ~handles.tbShowRV.Value, handles.line_rv.Visible = 'off'; end
if ~handles.tbShowLH.Value, handles.line_lh.Visible = 'off'; end
if ~handles.tbShowLV.Value, handles.line_lv.Visible = 'off'; end

% saccades
if handles.tbSaccadesLeftVert.Value || sum(arrayfun(@(x)strcmp(x.type,'lv'),handles.restore_data.sacc_disabled))>0 ...
		|| sum(arrayfun(@(x)strcmp(x.type,'lv'),handles.restore_data.sacc_labels))>0
	createSaccLines(handles, 'l', 'v');
	if ~handles.tbSaccadesLeftVert.Value
		hideSaccades(handles, 'left', 'vertical');
	end
end
if handles.tbSaccadesRightVert.Value || sum(arrayfun(@(x)strcmp(x.type,'rv'),handles.restore_data.sacc_disabled))>0 ...
		|| sum(arrayfun(@(x)strcmp(x.type,'rv'),handles.restore_data.sacc_labels))>0
	createSaccLines(handles, 'r', 'v');
	if ~handles.tbSaccadesRightVert.Value
		hideSaccades(handles, 'right', 'vertical');
	end
end
if handles.tbSaccadesLeftHoriz.Value || sum(arrayfun(@(x)strcmp(x.type,'lh'),handles.restore_data.sacc_disabled))>0 ...
		|| sum(arrayfun(@(x)strcmp(x.type,'lh'),handles.restore_data.sacc_labels))>0
	createSaccLines(handles, 'l', 'h');
	if ~handles.tbSaccadesLeftHoriz.Value
		hideSaccades(handles, 'left', 'horizontal');
	end
end
if handles.tbSaccadesRightHoriz.Value || sum(arrayfun(@(x)strcmp(x.type,'rh'),handles.restore_data.sacc_disabled))>0 ...
		|| sum(arrayfun(@(x)strcmp(x.type,'rh'),handles.restore_data.sacc_labels))>0
	createSaccLines(handles, 'r', 'h');
	if ~handles.tbSaccadesRightHoriz.Value
		hideSaccades(handles, 'right', 'horizontal');
	end
end

% restore the saccade begin menus/labels
if ~isempty(handles.restore_data.sacc_disabled) || ~isempty(handles.restore_data.sacc_labels)
% 	sacc_lines = findobj(handles.axes_eye, '-regexp', 'Tag',  'sacc.*begin');
	for ds_cnt = 1:length(handles.restore_data.sacc_disabled)		
		hs_line = findobj(handles.figure1,'xdata',handles.restore_data.sacc_disabled(ds_cnt).xdata,...
			'-regexp','Tag',['.*' handles.restore_data.sacc_disabled(ds_cnt).type '.*']);
		hs_menu_disable = findobj(hs_line.UIContextMenu.Children, 'Label', 'Disable Saccade');
		disableSaccade(hs_menu_disable, []);
	end
	for s_cnt = 1:length(handles.restore_data.sacc_labels)
		hs_line = findobj(handles.figure1,'xdata',handles.restore_data.sacc_labels(s_cnt).xdata,...
			'-regexp','Tag',['.*' handles.restore_data.sacc_labels(s_cnt).type '.*']);
		hs_menu_label = findobj(hs_line.UIContextMenu.Children, 'Label', handles.restore_data.sacc_labels(s_cnt).label);
		labelSaccade(hs_menu_label, [], handles.restore_data.sacc_labels(s_cnt).label)
		%hs_menu_label.Checked = 'on';
	end
end

% blinks
for b_cnt = 1:length(handles.restore_data.blinks)
	 createBox([], [], handles.restore_data.blinks{b_cnt}, 'blink')
	 if ~handles.tbExcludeBlinks.Value
		 hideBlinks(handles)
	 end
end

% annotations (mistakes)
if isfield(handles, 'axes_hand')
	for a_cnt = 1:length(handles.restore_data.annots)
      handles = addAxesLine(handles, handles.restore_data.annots(a_cnt).xdata, handles.restore_data.annots(a_cnt).txt, 'on');
	end
end
guidata(handles.figure1, handles)

% exclude patches
for b_cnt = 1:length(handles.restore_data.excludes)
	 createBox([], [], handles.restore_data.excludes{b_cnt}, 'exclude')
	 handles = guidata(handles.figure1);
end

% analyze patches
for b_cnt = 1:length(handles.restore_data.analysis)
	 createBox([], [], handles.restore_data.analysis(b_cnt).Vertices, ...
		 ['analysis' char(handles.restore_data.analysis(b_cnt).type) ])
	 handles = guidata(handles.figure1);
end

% moves/reaches
for r_cnt = 1:length(handles.restore_data.reaches)
	h_axes = findobj(handles.figure1, 'Tag', handles.restore_data.reaches(r_cnt).axes_tag);
	axes(h_axes)
	handles = createReachLine(handles, h_axes, handles.restore_data.reaches(r_cnt).begin, ...
		handles.restore_data.reaches(r_cnt).end, handles.restore_data.reaches(r_cnt).bps);
end

% saccade targets
if isfield(handles.restore_data, 'target_data')
	handles.target_data = handles.restore_data.target_data;
	handles.target_pos = handles.restore_data.target_pos;
	axes(handles.axes_eye)
	handles.line_target_x = line(handles.target_data.t, handles.target_data.x, 'Tag', 'line_target_x', 'Color', 'b');
	handles.line_target_y = line(handles.target_data.t, handles.target_data.y, 'Tag', 'line_target_y', 'Color', 'c');

	if ~handles.tbTargetH.Value
		set(handles.line_target_x, 'Visible', 'off')
	end
	if ~handles.tbTargetV.Value
		set(handles.line_target_y, 'Visible', 'off')
	end
end

% click data
if isfield(handles.restore_data, 'click_data_tbl')
	handles.click_filename = handles.restore_data.click_filename;
	handles.click_data_tbl = handles.restore_data.click_data_tbl;
	handles.im_data = handles.restore_data.im_data;
	
	imshow(handles.im_data, 'Parent', handles.axes_video, 'XData', [0 1024], 'YData', [0 768] )

	% eye position overlay on pciture
	handles.axes_video_overlay.Color = 'none';
	handles.axes_video_overlay.Visible = 'off';
	xmin_max = handles.eye_data.h_pix_z / 30;
	ymin_max = handles.eye_data.v_pix_z / 30;
	handles.axes_video_overlay.XLim = [-xmin_max xmin_max];
	handles.axes_video_overlay.YLim = [-ymin_max ymin_max];
	display_eye_pos_overlay(handles, 1/handles.eye_data.samp_freq)
	% scrub line
	handles = add_scrub_lines(handles, handles.restore_data.scrub_line_eye.XData(1));

	% mouse clicks
	handles = display_mouse_clicks(handles);
end
return



% --- Executes on button press in pbTarget.
function pbTarget_Callback(hObject, eventdata, handles)
% hObject    handle to pbTarget (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = parse_msg_file_for_targets(handles);
guidata(handles.figure1, handles)
return

% --- Executes on button press in pbPictDiff.
function pbPictDiff_Callback(hObject, eventdata, handles)
% hObject    handle to pbPictDiff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = get_image_and_clicks(handles);
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


% --- Executes on selection change in popmenuSaccType.
function popmenuSaccType_Callback(hObject, eventdata, handles)
% hObject    handle to popmenuSaccType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

sacc_type = lower(hObject.String{hObject.Value});

if strcmp(sacc_type, 'eyelink')
	sacc_type_str = 'EDF_PARSER';
else
	sacc_type_str = sacc_type;
end
% check the eye data for existing sacccades of the type chosen
have_this_type = false;
for s_cnt = 1:length(handles.eye_data.rh.saccades)
	if strcmp(handles.eye_data.rh.saccades(s_cnt).paramtype, sacc_type_str)
		% have saccades of this type
		have_this_type = true;
	end
end

if ~have_this_type % don't have this type
	% read them in 
	handles = get_saccades(handles, sacc_type_str);
	% enable all saccades
	handles.eye_data = enable_all_saccades(handles.eye_data);
	
	guidata(handles.figure1, handles)
end
% if any saccades are showing, hide & reshow them so they are updated with
% the new type
if handles.tbSaccadesLeftHoriz.Value
	hideSaccades(handles, 'l', 'h', hObject.UserData.prev_choice)
	showSaccades(handles, 'l', 'h')
end
if handles.tbSaccadesLeftVert.Value
	hideSaccades(handles, 'l', 'v', hObject.UserData.prev_choice)
	showSaccades(handles, 'l', 'v')
end
if handles.tbSaccadesRightHoriz.Value
	hideSaccades(handles, 'r', 'h', hObject.UserData.prev_choice)
	showSaccades(handles, 'r', 'h')
end
if handles.tbSaccadesRightVert.Value
	hideSaccades(handles, 'r', 'v', hObject.UserData.prev_choice)
	showSaccades(handles, 'r', 'v')
end
hObject.UserData.prev_choice = sacc_type;
return



% --- Executes during object creation, after setting all properties.
function popmenuSaccType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popmenuSaccType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
hObject.UserData.prev_choice = lower(hObject.String{hObject.Value});
return


% --- Executes on button press in tbVergence.
function tbVergence_Callback(hObject, eventdata, handles)
% hObject    handle to tbVergence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'line_vergence')
	if get(hObject,'Value') % returns toggle state
		set(handles.line_vergence, 'Visible', 'on')
	else
		set(handles.line_vergence, 'Visible', 'off')
	end
end
return

% --- Executes on button press in tbConjugate.
function tbConjugate_Callback(hObject, eventdata, handles)
% hObject    handle to tbConjugate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'line_conjugate')
	if get(hObject,'Value') % returns toggle state
		set(handles.line_conjugate, 'Visible', 'on')
	else
		set(handles.line_conjugate, 'Visible', 'off')
	end
end
return

% --- Executes on button press in tbVergenceVelocity.
function tbVergenceVelocity_Callback(hObject, eventdata, handles)
% hObject    handle to tbVergenceVelocity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'line_vergence_velocity')
	if get(hObject,'Value') % returns toggle state
		set(handles.line_vergence_velocity, 'Visible', 'on')
	else
		set(handles.line_vergence_velocity, 'Visible', 'off')
	end
end
return


% --- Executes on button press in tbLHVel.
function tbLHVel_Callback(hObject, eventdata, handles)
% hObject    handle to tbLHVel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'line_lh_velocity')
	if get(hObject,'Value') % returns toggle state
		set(handles.line_lh_velocity, 'Visible', 'on')
	else
		set(handles.line_lh_velocity, 'Visible', 'off')
	end
end
return

% --- Executes on button press in tbRHVel.
function tbRHVel_Callback(hObject, eventdata, handles)
% hObject    handle to tbRHVel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'line_rh_velocity')
	if get(hObject,'Value') % returns toggle state
		set(handles.line_rh_velocity, 'Visible', 'on')
	else
		set(handles.line_rh_velocity, 'Visible', 'off')
	end
end
return



function editLPFilt_Callback(hObject, eventdata, handles)
% hObject    handle to editLPFilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLPFilt as text
%        str2double(get(hObject,'String')) returns contents of editLPFilt as a double
handles = create_verg_vel_lines(handles);
guidata(handles.figure1, handles)


% --- Executes during object creation, after setting all properties.
function editLPFilt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLPFilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in rb_right_eye_viewing.
function rb_right_eye_viewing_Callback(hObject, eventdata, handles)
% hObject    handle to rb_right_eye_viewing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_right_eye_viewing


% --- Executes on button press in rb_left_eye_viewing.
function rb_left_eye_viewing_Callback(hObject, eventdata, handles)
% hObject    handle to rb_left_eye_viewing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_left_eye_viewing


% --- Executes on button press in chkbx_head.
function chkbx_head_Callback(hObject, eventdata, handles)
% hObject    handle to chkbx_head (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkbx_head


% --- Executes on button press in chkbx_right.
function chkbx_right_Callback(hObject, eventdata, handles)
% hObject    handle to chkbx_right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkbx_right


% --- Executes on button press in chkbx_left_hand.
function chkbx_left_hand_Callback(hObject, eventdata, handles)
% hObject    handle to chkbx_left_hand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkbx_left_hand
