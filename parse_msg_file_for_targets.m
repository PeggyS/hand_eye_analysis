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

handles.target_pos.type = target_type;
% if smoothp
switch target_type
   case 'smoothp'
      % , remove '_#_' from the msg.asc filename
      rem_str = regexpi(msg_fname, '_\d', 'match');
      msg_fname = strrep(msg_fname, rem_str{1}, '');
      % set the index of the 'TARGET_POS' msg
      target_pos_ind = 5;
      blank_msg_ind = 4;
      blank_msg = 'blank_screen';
      x_pos_ind = 7;
      y_pos_ind = 8;
   case 'ecc_gaze'
      %       keyboard
      % , remove '_#_' from the msg.asc filename
      rem_str = regexpi(msg_fname, '_\d', 'match');
      msg_fname = strrep(msg_fname, rem_str{1}, '');
      % set the index of the 'TARGET_POS' msg
      target_pos_ind = [4 5];
      blank_msg_ind = 4;
      blank_msg = 'Blank_display';
      x_pos_ind = [5 7];
      y_pos_ind = [6 8];
   case 'sacc'
      % set the index of the 'TARGET_POS' msg
      target_pos_ind = 4;
      blank_msg_ind = 4;
      blank_msg = 'Blank_display';
      x_pos_ind = 5;
      y_pos_ind = 6;
end

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

handles.target_pos.type = target_type;

target_cnt = 0;
for line_cnt = 1:length(msgs)
   % 	if line_cnt > 1914
   % 		keyboard
   % 	end
   word_list = split(msgs{line_cnt,:});
   if strcmpi(word_list{1}, 'msg')
   t_event = parse_wordlist_for_tevent(word_list);
  
   if ~isempty(t_event) && t_event > handles.eye_data.start_times && ...
         t_event <= handles.eye_data.start_times + handles.target_data.t(end)*1000
      
      % 	if length(word_list) >= target_pos_ind && strcmpi(word_list{target_pos_ind}, 'TARGET_POS')
      if parse_wordlist_for_str(word_list, 'TARGET_POS')
         
         % 		if length(word_list) >= y_pos_ind && strcmpi(word_list{target_pos_ind}, 'TARGET_POS')
         target_cnt = target_cnt + 1;
         % 			t_str = regexp(word_list{2}, '\d*', 'match'); % the millisecond number after 'MSG'
         % 			t2_str = regexp(word_list{3}, '\d*', 'match'); % the additional milliseconds to add to the first number to get the actual time of the event
         % 			t_event = str2double(t_str{1}) + str2double(t2_str{1});
         t_event = parse_wordlist_for_tevent(word_list);
         handles.target_pos.t_start_abs_ms(target_cnt) = t_event;
         handles.target_pos.t_start(target_cnt) = (t_event - handles.eye_data.start_times)/1000; % relative to the data collection start time (in sec)
         % 			x_str = regexp(word_list{x_pos_ind}, '\d*', 'match');
         % 			handles.target_pos.x_pos(target_cnt) = str2double(x_str{1});
         % 			y_str = regexp(word_list{y_pos_ind}, '\d*', 'match');
         % 			handles.target_pos.y_pos(target_cnt) = str2double(y_str{1});
         [handles.target_pos.x_pos(target_cnt), handles.target_pos.y_pos(target_cnt)] ...
            = parse_wordlist_for_xy(word_list);
         
         % convert pos to degrees
         handles.target_pos.x_deg(target_cnt) =  (handles.target_pos.x_pos(target_cnt)-handles.eye_data.h_pix_z ) ...
            /30; % 30 pix per deg as defined on the screen
         handles.target_pos.y_deg(target_cnt) =  -(handles.target_pos.y_pos(target_cnt)-handles.eye_data.v_pix_z ) ...
            /30;
         % 		end
         % 	elseif length(word_list) >= blank_msg_ind &&  strcmpi(word_list{blank_msg_ind}, blank_msg)
      elseif parse_wordlist_for_str(word_list, blank_msg) || parse_wordlist_for_str(word_list, 'End_trial_display')
         % 		t_str = regexp(word_list{2}, '\d*', 'match'); % the millisecond number after 'MSG'
         % 		t2_str = regexp(word_list{3}, '\d*', 'match'); % the additional milliseconds to add to the first number to get the actual time of the event
         % 		t_event = str2double(t_str{1}) + str2double(t2_str{1});
         
         % or End_trial_display for end of ecc_gaze trial
         
         t_event = parse_wordlist_for_tevent(word_list);
         handles.target_pos.t_end(target_cnt) = (t_event- handles.eye_data.start_times)/1000; % relative to the data collection start time (in sec)
         % 		t_blank_time_abs_ms = t_event;
         %
         %       % if the blank_screen msg is in this eyedata time segment
         %             if t_blank_time_abs_ms > handles.eye_data.start_times && ...
         %                   t_blank_time_abs_ms <= handles.eye_data.start_times + handles.target_data.t(end)*1000
         % update target vector
         switch target_type
            case {'sacc' 'ecc_gaze'}
               % 		if strcmp(target_type, 'sacc')
               % saccades: target is at a constant value between handles.target_pos.t_start and target_pos.t_end
               handles.target_data.x(handles.target_data.t>=handles.target_pos.t_start(target_cnt) ...
                  & handles.target_data.t<handles.target_pos.t_end(target_cnt)) = handles.target_pos.x_deg(target_cnt);
               handles.target_data.y(handles.target_data.t>=handles.target_pos.t_start(target_cnt) ...
                  & handles.target_data.t<handles.target_pos.t_end(target_cnt)) = handles.target_pos.y_deg(target_cnt);
               % 		else
            case 'smoothp'
               
               %             % if the blank_screen msg is in this eyedata time segment
               %             if t_blank_time_abs_ms > handles.eye_data.start_times && ...
               %                   t_blank_time_abs_ms <= handles.eye_data.start_times + handles.target_data.t(end)*1000
               % 				keyboard
               abs_targ_beg_ind = find(handles.target_pos.t_start_abs_ms>=handles.eye_data.start_times,1,'first');
               abs_targ_end_ind = find(handles.target_pos.t_start_abs_ms<=t_event,1,'last');
               
               targ_t=handles.target_pos.t_start(abs_targ_beg_ind:abs_targ_end_ind);
               targ_x=handles.target_pos.x_deg(abs_targ_beg_ind:abs_targ_end_ind);
               targ_y=handles.target_pos.y_deg(abs_targ_beg_ind:abs_targ_end_ind);
               
               % 				abs_ms_target_begin = handles.target_pos.t_start_abs_ms(abs_targ_beg_ind);
               % 				rel_targ_beg = (abs_ms_target_begin-handles.eye_data.start_times)/1000;
               % 				rel_targ_end = (t_blank_time_abs_ms-handles.eye_data.start_times)/1000;
               beg_ind = find(handles.target_data.t >= targ_t(1), 1, 'first');
               end_ind = find(handles.target_data.t <= targ_t(end), 1, 'last');
               
               handles.target_data.x(beg_ind:end_ind) = spline(targ_t, targ_x, handles.target_data.t(beg_ind:end_ind));
               handles.target_data.y(beg_ind:end_ind) = spline(targ_t, targ_y, handles.target_data.t(beg_ind:end_ind));
               %             end
               %          case 'ecc_gaze'
               %             keyboard
         end
      end % 
   end % if msg is in the time of this data record
   end % if it is a msg line
end % each msg
% draw the target lines
axes(handles.axes_eye)
handles.line_target_x = line(handles.target_data.t, handles.target_data.x, 'Tag', 'line_target_x', 'Color', 'b');
handles.line_target_y = line(handles.target_data.t, handles.target_data.y, 'Tag', 'line_target_y', 'Color', 'm');

% set toggle buttons to show both lines
set(handles.tbTargetH, 'Value', 1, 'Visible', 'on')
set(handles.tbTargetV, 'Value', 1, 'Visible', 'on')
return

% -------------------------
function found = parse_wordlist_for_str(word_list, str)
found = false;

for word_cnt = 1:length(word_list)
   found = strcmpi(word_list{word_cnt}, str);
   if found
      return
   end
end
return

function [x, y] = parse_wordlist_for_xy(word_list)
x=[]; y=[];

pat_x = '\(\d+';
pat_y = '\d+\)';

for word_cnt = 1:length(word_list)
   match_x = regexp(word_list{word_cnt}, pat_x, 'match');
   match_y = regexp(word_list{word_cnt}, pat_y, 'match');
   if ~isempty(match_x)
      x = str2double(strrep(match_x{1},'(', ''));
   end
   if ~isempty(match_y)
      y = str2double(strrep(match_y{1},')', ''));
      return
   end
end
return


function t_event = parse_wordlist_for_tevent(word_list)
t_event = [];
   t_str = regexp(word_list{2}, '\d*', 'match'); % the millisecond number after 'MSG'
	t2_str = regexp(word_list{3}, '\d*', 'match'); % the additional milliseconds to add to the first number to get the actual time of the event
   if ~isempty(t_str) && ~isempty(t2_str)
      t_event = str2double(t_str{1}) + str2double(t2_str{1});
   end
return