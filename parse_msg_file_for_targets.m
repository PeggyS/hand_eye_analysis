function handles = parse_msg_file_for_targets(handles, target_type)
% read in the msgs.asc file. Look for MSG lines with TARGET_POS TARG1
% the following numbers in () is the target pos in screen pixels
%
% target_type is either 'sacc' or 'smoothp' 
% 'sacc' targets use 'Blank_display' to determine when the target is turned
% off. 'Sacc' targets are held at a fixed value (the x y pos) specified
% until the 'blank_display' msg.
% 'smoothp' targets are for smooth pursuit. The positions, if they don't
% cooincide with the eye data time samples, are interpolated (or spline
% fit) to be a sinusoid. Target end with the msg 'blank_screen'

% the msg file name
msg_fname = strrep(handles.bin_filename, '.bin', '_msgs.asc');

if ~exist(msg_fname, 'file')
	disp('Choose _msg.asc file ...')
	[fnSave, pnSave] = uigetfile({'*.asc'}, 'Choose  _msg.asc file ...');
	if isequal(fnSave,0) || isequal(pnSave,0)
	   disp('no  file chosen ... ')
	   return
	end
	msg_fname = fullfile(pnSave, fnSave);
end

% target time vector is same as eye_data
handles.target_data.t = (1:handles.eye_data.numsamps)/handles.eye_data.samp_freq;
handles.target_data.x = nan(size(handles.target_data.t));
handles.target_data.y = nan(size(handles.target_data.t));

% parse the info in the file

% read in
msgs = importdata(msg_fname, char(13)); % each line is read in as a cell


target_cnt = 0;
for line_cnt = 1:length(msgs)
	word_list = split(msgs{line_cnt,:});
	if length(word_list) >= 4 && (strcmpi(word_list{4}, 'TARGET_POS') || strcmpi(word_list{4}, 'Blank_display'))
		% for each target presentation, there should be a TARGET_POS MSG
		% followed by a Blank_display MSG
		if length(word_list) >= 6 && strcmpi(word_list{4}, 'TARGET_POS')
			target_cnt = target_cnt + 1;
			t_str = regexp(word_list{2}, '\d*', 'match'); % the millisecond number after 'MSG'
			t2_str = regexp(word_list{3}, '\d*', 'match'); % the additional milliseconds to add to the first number to get the actual time of the event
			t_event = str2double(t_str{1}) + str2double(t2_str{1});
			handles.target_pos(target_cnt).t_start = (t_event - handles.eye_data.start_times)/1000; % relative to the data collection start time (in sec)
			x_str = regexp(word_list{5}, '\d*', 'match');
			handles.target_pos(target_cnt).x_pos = str2double(x_str{1});
			y_str = regexp(word_list{6}, '\d*', 'match');
			handles.target_pos(target_cnt).y_pos = str2double(y_str{1});
			
			% convert pos to degrees
			handles.target_pos(target_cnt).x_deg =  (handles.target_pos(target_cnt).x_pos-handles.eye_data.h_pix_z ) ...
				/30; % 30 pix per deg as defined on the screen
			handles.target_pos(target_cnt).y_deg =  -(handles.target_pos(target_cnt).y_pos-handles.eye_data.v_pix_z ) ...
				/30;
			
		elseif strcmpi(word_list{4}, 'Blank_display')
			t_str = regexp(word_list{2}, '\d*', 'match'); % the millisecond number after 'MSG'
			t2_str = regexp(word_list{3}, '\d*', 'match'); % the additional milliseconds to add to the first number to get the actual time of the event
			t_event = str2double(t_str{1}) + str2double(t2_str{1});
			handles.target_pos(target_cnt).t_end = (t_event- handles.eye_data.start_times)/1000; % relative to the data collection start time (in sec)
			% update target vector
			handles.target_data.x(handles.target_data.t>=handles.target_pos(target_cnt).t_start ...
				& handles.target_data.t<handles.target_pos(target_cnt).t_end) = handles.target_pos(target_cnt).x_deg;
			handles.target_data.y(handles.target_data.t>=handles.target_pos(target_cnt).t_start ...
				& handles.target_data.t<handles.target_pos(target_cnt).t_end) = handles.target_pos(target_cnt).y_deg;
		end
	end
end




return
