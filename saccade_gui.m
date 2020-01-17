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

% Last Modified by GUIDE v2.5 18-May-2019 17:26:06

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

% Choose default command line output for saccade_gui
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

% is this vergence data? if so get the vergence cal file and recalibrate
% for vergence
answer = input('Apply vergence calibration to the horizontal data (y/n)? ', 's');
if strcmpi(answer, 'y')
		% calibrate the data with the vergence cal_info
	% look for the Left & Right_verg_cal.mat files
	if ~isempty(handles.eye_data.rh.pos)
		if ismac
			[~, rcal_fname] = system('mdfind -onlyin ../ -name Right_verg_cal.mat');
			handles.rcal_fname = strtrim(rcal_fname);
		else
			handles.rcal_fname = '';
		end
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
			handles.eye_data.rh.pos = apply_vergence_cal(handles.eye_data.rh.pos, handles.rcal_info, false);
% 			handles.eye_data.rh.pos_verge_cal = apply_vergence_cal(handles.eye_data.rh.pos, handles.rcal_info, false);
% 			handles.line_rh = line(t, handles.eye_data.rh.pos_verge_cal, 'Tag', 'line_rh', 'Color', 'g');
% 		else
% 			handles.line_rh = line(t, handles.eye_data.rh.pos, 'Tag', 'line_rh', 'Color', 'g');
		end
	end
	
	if ~isempty(handles.eye_data.lh.pos)
		if ismac
			[~, lcal_fname] = system('mdfind -onlyin ../ -name Left_verg_cal.mat');
			handles.lcal_fname = strtrim(lcal_fname);
		else
			handles.lcal_fname = '';
		end
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
			handles.eye_data.lh.pos = apply_vergence_cal(handles.eye_data.lh.pos, handles.lcal_info, false);
% 			handles.eye_data.lh.pos_verge_cal = apply_vergence_cal(handles.eye_data.lh.pos, handles.lcal_info, false);
% 			handles.line_lh = line(t, handles.eye_data.lh.pos_verge_cal, 'Tag', 'line_lh', 'Color', 'r');
% 		else
% 			handles.line_lh = line(t, handles.eye_data.lh.pos, 'Tag', 'line_lh', 'Color', 'r');
		end
	end

end


% initialize the data in the axes
axes(handles.axes_eye)
if ~isempty(handles.eye_data.rh.pos)
	handles.line_rh = line(t, handles.eye_data.rh.pos, 'Tag', 'line_rh', 'Color', [0 .8 0]);
	handles.tbDataRightHoriz.Value = 1;
end
if ~isempty(handles.eye_data.lh.pos)
	handles.line_lh = line(t, handles.eye_data.lh.pos, 'Tag', 'line_lh', 'Color', [0.8 0 0]);
	handles.tbDataLeftHoriz.Value = 1;
end
if ~isempty(handles.eye_data.rv.pos)
	handles.line_rv = line(t, handles.eye_data.rv.pos, 'Tag', 'line_rv', 'Color', [0 1 0]);
	handles.tbDataRightVert.Value = 1;
end
if ~isempty(handles.eye_data.lv.pos)
	handles.line_lv = line(t, handles.eye_data.lv.pos, 'Tag', 'line_lv', 'Color', [1 0 0]);
	handles.tbDataLeftVert.Value = 1;
end
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

beg_line_color = getLineColor(h, ['saccade_' eye_str '_' sacc_source '_begin']);
end_line_color = getLineColor(h, ['saccade_' eye_str '_' sacc_source '_end']);
samp_freq = h.eye_data.samp_freq;

switch sacc_source
	case 'eyelink'
		start_ms = h.eye_data.start_times;
		sacclist = h.eye_data.(eye_str).saccades.sacclist; % eyelink data
		sacc_marker = 'o';
	case 'findsaccs'
        % get parameter values
        thresh_a = str2double(h.edAccelThresh.String);
        acc_stop = str2double(h.edAccelStop.String);
        thresh_v = str2double(h.edVelThresh.String);
        vel_stop = str2double(h.edVelStop.String);
        gap_fp = str2double(h.edGapFP.String);
        gap_sp = str2double(h.edGapSP.String);
        vel_or_acc = h.popmenuAccelVel.Value; % 1=Accel, 2=Vel, 3=Both
        extend = str2double(h.edExtend.String);
        range = [];
        direction = '';
%         dataName = 'unknown';
%         strict_strip = 1;
%         [ptlist, pvlist] = findsaccs(h.eye_data.(eye_str).pos, thresh_a, thresh_v, acc_stop, ...
% 			vel_stop, gap_fp, gap_sp, vel_or_acc, extend, dataName, strict_strip);
 %         saccstart = evalin('base','saccstart');
%         saccstop = evalin('base','saccstop');
        foundsaccs = findsaccs(h.eye_data.(eye_str).pos, thresh_a, thresh_v, acc_stop, ...
            vel_stop, gap_fp, gap_sp, vel_or_acc, extend, range, direction);
            % foundsaccs stuct:
            %    num    : number found in segment
            %    ptlist : map of segment: saccade==0, non-saccade==1
            %    pvel   : list of peak velocities
            %    pv_ind : sample indices of peak velocities
			%    detcrit: criteria (vel and/or acc) used to detect saccade
            %    v_sacc_beg, v_sacc_end : saccade begin/end (using vel criteria)
            %    a_sacc_beg, a_sacc_end : saccade begin/end (using acc criteria)
            %    start, stop            : saccade begin/end (final selection)
        saccstart = foundsaccs.start;
        saccstop = foundsaccs.stop;
        % saccstart sometimes has repeats (maybe) & nans (absolutely has nans)
         nonnanstart = find(~isnan(saccstart));
		 nonnanstop = find(~isnan(saccstop));
		 nonnans = intersect(nonnanstart, nonnanstop);
		 saccstart = saccstart(nonnans);
		 saccstop = saccstop(nonnans);
		 peak_vel  = foundsaccs.pvel(nonnans);   % indices of peak velocities
		 
         youneek = find(unique(saccstart));     % indices of unique saccade starts

         saccstart = saccstart(youneek); % indices of saccade starts
         saccstop  = saccstop(youneek);  % indices of saccade stops
         peak_vel  = peak_vel(youneek);   % indices of peak velocities
		 
% 		 % check the saccades for each start to have a matching stop
% 		 % if there are more than 1 starts in a row or stops in a row
		start_ms = 1/samp_freq;
		 for s_cnt = 1:length(saccstart)
			 if (saccstart(s_cnt) - start_ms)/1000 > 5.4 %in seconds% time > 5.4
%  				 keyboard
			 end
			
		 end
        
        % convert index values to time in ms
        sacclist.start = saccstart / samp_freq * 1000;
        sacclist.end = saccstop / samp_freq * 1000;
		sacclist.peak_vel = peak_vel;
		
		sac_type_num = 1;
		if isfield(h.eye_data.(eye_str), 'saccades')
			sac_type_num = length(h.eye_data.(eye_str).saccades) +1; % (index of the next type of saccades to store)
		end
		h.eye_data.(eye_str).saccades(sac_type_num).sacclist = sacclist;
		h.eye_data.(eye_str).saccades(sac_type_num).sacclist.start = h.eye_data.(eye_str).saccades(sac_type_num).sacclist.start ...
																		+ h.eye_data.start_times;
		h.eye_data.(eye_str).saccades(sac_type_num).sacclist.end = h.eye_data.(eye_str).saccades(sac_type_num).sacclist.end ...
																		+ h.eye_data.start_times;
		h.eye_data.(eye_str).saccades(sac_type_num).paramtype = 'findsaccs';

		h.eye_data.(eye_str).saccades(sac_type_num).foundsaccs = foundsaccs;
	
	% do the same thing for engbert saccades

		% FIXME - remove this findsacc_data struct and use
		% h.eye_data.(eye_str).saccades instead 
		% then change the saved data 
	
% 		h.findsacc_data.(eye_str).start = sacclist.start + h.eye_data.start_times;
%         h.findsacc_data.(eye_str).end = sacclist.end + h.eye_data.start_times;
% 		h.findsacc_data.(eye_str).peak_vel = sacclist.peak_vel;
		
		% save new figure handles
		guidata(h.figure1, h)
		
		sacc_marker = 's';
		
	case 'engbert'
		% get parameters
		vel_factor = str2double(h.edVelFactor.String);
		min_num_samples = round(str2double(h.edMinSaccDur.String)/1000 * samp_freq);
		
		h_str = strrep(eye_str, 'v', 'h');
		v_str = strrep(eye_str, 'h', 'v');
		% eye data converted to angular minutes of arc (from degrees)
		x = [h.eye_data.(h_str).pos h.eye_data.(v_str).pos] * 60;
		
		% velocity using function from Asef
		v = vecvel(x, samp_freq, 2);
		
		% compute saccades using function from Engbert
		sac = microsacc_ps(x, v, vel_factor, min_num_samples);
		%   sac(1:num,1)   onset of saccade
		%   sac(1:num,2)   end of saccade
		%   sac(1:num,3)   peak velocity of saccade
		%   sac(1:num,4)   saccade amplitude
		%   sac(1:num,5)   angular orientation 
		%   sac(1:num,6)   horizontal component (delta x)
		%   sac(1:num,7)   vertical component (delta y)
		%   sac(1:num,8)   peak velocity horizontal component 
		%   sac(1:num,9)   peak velocity vertical component 
		
		% if binocular only saccades
		if h.chbxBinocular.Value
			% get the other eye's engbert saccades
			if strcmp(h_str(1), 'l')
				ho_str=['r' h_str(2)];
				vo_str=['r' v_str(2)];
			else
				ho_str=['l' h_str(2)];
				vo_str=['l' v_str(2)];
			end
			x_other = [h.eye_data.(ho_str).pos h.eye_data.(vo_str).pos] * 60;
			v_other = vecvel(x_other, samp_freq, 2);
			sac_other = microsacc_ps(x_other, v_other, vel_factor, min_num_samples);
			
			sac = binsacc_ps(sac, sac_other);
		end
		
		% save saccades in handles
		start_ms = 1/samp_freq;
		sacclist.start_ind = sac(:,1)';
		sacclist.end_ind = sac(:,2)';
		sacclist.start = sac(:,1)' / samp_freq * 1000; % time in ms
        sacclist.end = sac(:,2)' / samp_freq * 1000;
		sacclist.peak_vel = sac(:,3)'/60;	% converting from minutes to degrees
		sacclist.sacc_ampl = sac(:,4)'/60;
		sacclist.sacc_horiz_component = sac(:,6)'/60;
		sacclist.sacc_vert_component = sac(:,7)'/60;
		sacclist.peak_vel_horiz_component = sac(:,8)'/60;
		sacclist.peak_vel_vert_component = sac(:,9)'/60;
		
		% impose minimum intersaccade interval
		isi = str2double(h.edInterSaccInterval.String);
		if length(sacclist.start) > 1 && isi > 0
			% if intersacc interval < isi, delete the 2nd saccade
			sacc_intervals = sacclist.start(2:end)-sacclist.end(1:end-1);
			inds = find(sacc_intervals<isi);
			sacclist.start_ind(inds+1) = [];
			sacclist.end_ind(inds+1) = [];
			sacclist.start(inds+1) = [];
			sacclist.end(inds+1) = [];
			sacclist.peak_vel(inds+1) = [];
			sacclist.sacc_ampl(inds+1) = [];
			sacclist.sacc_horiz_component(inds+1) = [];
			sacclist.sacc_vert_component(inds+1) = [];
			sacclist.peak_vel_horiz_component(inds+1) = [];
			sacclist.peak_vel_vert_component(inds+1) = [];
		end
		sacclist = compute_diff_vel_peaks(sacclist, h.eye_data.(h_str).pos, h.eye_data.(v_str).pos, samp_freq);
		sacclist = compute_drift(sacclist, h.eye_data.(h_str).pos, h.eye_data.(v_str).pos, samp_freq);
		
		sac_type_num = 1;
		if isfield(h.eye_data.(eye_str), 'saccades')
			sac_type_num = length(h.eye_data.(eye_str).saccades) +1; % (index of the next type of saccades to store)
		end
		h.eye_data.(eye_str).saccades(sac_type_num).sacclist = sacclist;
		h.eye_data.(eye_str).saccades(sac_type_num).sacclist.start = h.eye_data.(eye_str).saccades(sac_type_num).sacclist.start ...
																		+ h.eye_data.start_times;
		h.eye_data.(eye_str).saccades(sac_type_num).sacclist.end = h.eye_data.(eye_str).saccades(sac_type_num).sacclist.end ...
																		+ h.eye_data.start_times;
		h.eye_data.(eye_str).saccades(sac_type_num).sacclist.as_peak_vel_horiz_time = sacclist.as_peak_vel_horiz_ind/samp_freq + h.eye_data.start_times/1000;
		h.eye_data.(eye_str).saccades(sac_type_num).sacclist.as_peak_vel_vert_time = sacclist.as_peak_vel_vert_ind/samp_freq + h.eye_data.start_times/1000;
		h.eye_data.(eye_str).saccades(sac_type_num).sacclist.as_drift_mean_time = sacclist.as_mean_ind/samp_freq + h.eye_data.start_times/1000;
		
		h.eye_data.(eye_str).saccades(sac_type_num).paramtype = 'engbert';
		
% 		h.engbertsacc_data.(eye_str).start_time = start_ms;
% 		h.engbertsacc_data.(eye_str).start = sacclist.start + h.eye_data.start_times;
%         h.engbertsacc_data.(eye_str).end = sacclist.end + h.eye_data.start_times;
% 		h.engbertsacc_data.(eye_str).peak_vel = sacclist.peak_vel;
% 		h.engbertsacc_data.(eye_str).sacc_ampl = sacclist.sacc_ampl;
% 		h.engbertsacc_data.(eye_str).sacc_horiz_component = sacclist.sacc_horiz_component;
% 		h.engbertsacc_data.(eye_str).sacc_vert_component = sacclist.sacc_vert_component;
% 		h.engbertsacc_data.(eye_str).peak_vel_horiz_component = sacclist.peak_vel_horiz_component;
% 		h.engbertsacc_data.(eye_str).peak_vel_vert_component = sacclist.peak_vel_vert_component;
% 		h.engbertsacc_data.(eye_str).as_ampl_horiz = sacclist.as_ampl_horiz;
% 		h.engbertsacc_data.(eye_str).as_ampl_vert = sacclist.as_ampl_vert;
% 		h.engbertsacc_data.(eye_str).as_peak_vel_horiz = sacclist.as_peak_vel_horiz;
% 		h.engbertsacc_data.(eye_str).as_peak_vel_vert = sacclist.as_peak_vel_vert;
% 		h.engbertsacc_data.(eye_str).as_peak_vel_horiz_time = sacclist.as_peak_vel_horiz_ind/samp_freq + h.eye_data.start_times/1000;
% 		h.engbertsacc_data.(eye_str).as_peak_vel_vert_time = sacclist.as_peak_vel_vert_ind/samp_freq + h.eye_data.start_times/1000;
% 
% 		h.engbertsacc_data.(eye_str).as_drift_mean_time = sacclist.as_mean_ind/samp_freq + h.eye_data.start_times/1000;
% 		h.engbertsacc_data.(eye_str).as_median_horiz	 = sacclist.as_median_horiz;
% 		h.engbertsacc_data.(eye_str).as_mean_horiz	 = sacclist.as_mean_horiz;
% 		h.engbertsacc_data.(eye_str).as_var_horiz	 = sacclist.as_var_horiz;
% 		h.engbertsacc_data.(eye_str).as_std_horiz	 = sacclist.as_std_horiz;
% 		h.engbertsacc_data.(eye_str).as_median_vert	 = sacclist.as_median_vert;
% 		h.engbertsacc_data.(eye_str).as_mean_vert	 = sacclist.as_mean_vert;
% 		h.engbertsacc_data.(eye_str).as_var_vert	 = sacclist.as_var_vert;
% 		h.engbertsacc_data.(eye_str).as_std_vert	 = sacclist.as_std_vert;
% 		h.engbertsacc_data.(eye_str).as_median_norm_vel	 = sacclist.as_median_norm_vel;
% 		h.engbertsacc_data.(eye_str).as_mean_norm_vel	 = sacclist.as_mean_norm_vel;
% 		h.engbertsacc_data.(eye_str).as_var_norm_vel	 = sacclist.as_var_norm_vel;
% 		h.engbertsacc_data.(eye_str).as_std_norm_vel	 = sacclist.as_std_norm_vel;
% 		h.engbertsacc_data.(eye_str).as_median_norm_pos	 = sacclist.as_median_norm_pos;
% 		h.engbertsacc_data.(eye_str).as_mean_norm_pos	 = sacclist.as_mean_norm_pos;
% 		h.engbertsacc_data.(eye_str).as_var_norm_pos	 = sacclist.as_var_norm_pos;
% 		h.engbertsacc_data.(eye_str).as_std_norm_pos	 = sacclist.as_std_norm_pos;
		% save new figure handles
		guidata(h.figure1, h)
		
		sacc_marker = 'd';
			
	case 'cluster'
		start_ms = h.eye_data.start_times;
		sacclist = h.eye_data.(eye_str).saccades.sacclist; % eyelink data
		sacc_marker = '^';
end
		
for sacc_num = 1:length(sacclist.start)
   % saccade begin
   time1 = (sacclist.start(sacc_num) - start_ms)/1000; %in seconds
%    if time1 > 5.4 %in seconds% time > 5.4
%  				 keyboard
% 			 end
   y = h.eye_data.(eye_str).pos(round(time1*samp_freq));
   h_beg_line = line( time1, y, 'Tag', ['saccade_' eye_str '_' sacc_source '_#' num2str(sacc_num) '_begin'], ...
      'Color', beg_line_color, 'Marker', sacc_marker, 'MarkerSize', 10);
   eye_m = uicontextmenu;
   h_beg_line.UIContextMenu = eye_m;
   uimenu(eye_m, 'Label', 'Disable Saccade', 'Callback', @disableSaccade, ...
      'Tag', ['menu_saccade_' eye_str '_' sacc_source '_#' num2str(sacc_num) '_begin']);
   
   % saccade end
   time2 = (sacclist.end(sacc_num) - start_ms)/1000;
   y = h.eye_data.(eye_str).pos(round(time2*samp_freq));
   line( time2, y, 'Tag', ['saccade_' eye_str '_' sacc_source '_#' num2str(sacc_num) '_end'], ...
      'Color', end_line_color, 'Marker', sacc_marker, 'MarkerSize', 10);
   
   % saccade segment
   sac_start_ind = round(time1*samp_freq);
   sac_stop_ind  = round(time2*samp_freq);
   if sac_stop_ind-sac_start_ind > 2	% if start and stop are consecutive time points, then there is no segment
	   tempdata = h.eye_data.(eye_str).pos;
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
tb_list(end+1) = findobj(handles.figure1, 'Tag', 'tbCluster');

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
tb_list(end+1) = findobj(handles.figure1, 'Tag', 'tbCluster');

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
tb_list(end+1) = findobj(handles.figure1, 'Tag', 'tbCluster');

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
tb_list(end+1) = findobj(handles.figure1, 'Tag', 'tbCluster');

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


% --- Executes on button press in pbLoadSaccTarget.
function pbLoadSaccTarget_Callback(hObject, eventdata, handles)
% hObject    handle to pbLoadSaccTarget (see GCBO)
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


% --- Executes on button press in tbCluster.
function tbCluster_Callback(hObject, eventdata, handles)
% hObject    handle to tbCluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% so we only need to compute these saccades once,
if isempty(hObject.UserData) % if user data is empty, then saccades have not been computed yet
	handles = do_cluster_saccades_swj(handles); % find the saccades
	hObject.UserData = 1;
	guidata(handles.figure1, handles)
	% save the info to a mat file
	fname = strrep(handles.bin_filename, '.bin', '_cluster.mat');
	eye_list = {'lh', 'rh', 'lv', 'rv'};
	for e_cnt = 1:length(eye_list)
		eye_str = eye_list{e_cnt};
		if isfield(handles.eye_data.(eye_str), 'saccades')
			for s_cnt = 1:length(handles.eye_data.(eye_str).saccades)
				if strcmp(handles.eye_data.(eye_str).saccades(s_cnt).paramtype, 'cluster')
					data.(eye_str).sacclist = handles.eye_data.(eye_str).saccades(s_cnt).sacclist;
				end
			end
		end
	end
	params = [];
	if exist('data','var')
		save(fname, 'data', 'params')
	end
end
	

% display the saccades on all the lines that are visible
if get(hObject,'Value') 
	if strcmp(handles.line_rv.Visible, 'on')
		showSaccades(handles, 'right','vertical', 'cluster');
	end
	if strcmp(handles.line_lv.Visible, 'on')
	   showSaccades(handles, 'left','vertical', 'cluster');
	end
	if strcmp(handles.line_rh.Visible, 'on')
	   showSaccades(handles, 'right','horizontal', 'cluster');
	end
	if strcmp(handles.line_lh.Visible, 'on')
	   showSaccades(handles, 'left','horizontal', 'cluster');
	end
   hObject.UserData = 'cluster'; % may not be necessary to save this here. Other tb's for saccades save the source of saccade here for showing & hiding lines when the data line is shown/hidden.
else
   hideSaccades(handles, 'right','vertical', 'cluster');
   hideSaccades(handles, 'left','vertical', 'cluster');
   hideSaccades(handles, 'right','horizontal', 'cluster');
   hideSaccades(handles, 'left','horizontal', 'cluster');
end
return


% --- Executes on button press in pbFindSaccsSWJ.
function pbFindSaccsSWJ_Callback(hObject, eventdata, handles)
% hObject    handle to pbFindSaccsSWJ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% swj = find_swj(found, data, samp_freq)
