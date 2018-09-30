function handles = get_led_data(handles)
% get the led data from the message file and distances from led_distances.csv
% change this. get led data from *_results.mat
% in results.mat:
% tgtpos = 
%   1×43 struct array with fields:
%     led
%     when
%     distance
%     angle
% tgtpos(1)
% ans = 
%   struct with fields:
% 
%          led: 0
%         when: 1830808
%     distance: []
%        angle: []
% tgtpos(2)
% ans = 
%   struct with fields:
% 
%          led: 9
%         when: 5899527
%     distance: 200
%        angle: 0

% when time is psychtoolbox time in ms
% in results.mat
% t = 
%   struct with fields:
% 
%      rec_startEL: 1830808
%     rec_startPTB: 5899450
%        cal_endEL: 1830808
%       cal_endPTB: 5899508
%      exp_startEL: 1830808
%     exp_startPTB: 5899508

% t.exp_startPTB = when the exp/eyelink recording started

% % get the led_distances.csv
% fname = 'led_distances.csv';
% [pathstr, ~, ~] = fileparts(handles.bin_filename);
% if exist(fullfile(pathstr, fname),'file') % if it's in the same folder as the data
% 	led_dist_tbl = readtable(fullfile(pathstr, fname));
% else
% 
% 	% go up 2 folder levels and look for the file
% 	[pathname,filename] = findfilepath(fname, '../..');
% 	if isempty(pathname)
% 		% request file location
% 			disp('choose led distances file ...')
% 			[fnImg, pnImg] = uigetfile({'*.*'}, 'Choose led distances file ...');
% 			if isequal(fnImg,0) || isequal(pnImg,0)
% 				disp('no led dist file')
% 				return
% 			else
% 				led_dist_tbl = readtable(fullfile(pnImg,fnImg));
% 			end
% 	else
% 		led_dist_tbl = readtable(fullfile(pathname,filename));
% 	end
% end

% % read in the msg file
% % the msg file name
% msg_fname = strrep(handles.bin_filename, '.bin', '_msgs.asc');
% if ~exist(msg_fname, 'file')
% 	disp('Choose _msg.asc file ...')
% 	[fnSave, pnSave] = uigetfile({'*.asc'}, 'Choose  _msg.asc file ...');
% 	if isequal(fnSave,0) || isequal(pnSave,0)
% 	   disp('no  file chosen ... ')
% 	   return
% 	end
% 	msg_fname = fullfile(pnSave, fnSave);
% end
% % read in
% msgs = importdata(msg_fname, char(13)); % each line is read in as a cell

% read in the results file
result_fname = strrep(handles.bin_filename, '.bin', '_results.mat');
if ~exist(result_fname, 'file')
	disp('Choose _results.mat file ...')
	[fnSave, pnSave] = uigetfile({'*.mat'}, 'Choose  _results.mat file ...');
	if isequal(fnSave,0) || isequal(pnSave,0)
	   disp('no  file chosen ... ')
	   return
	end
	result_fname = fullfile(pnSave, fnSave);
end
% read in
handles.led_results = load(result_fname);

% % add info to led_data_tbl 
% led_msg_cnt = 0;
% % continue reading from the found synctime
% for line_cnt = 1:length(msgs)
% 	word_list = split(msgs{line_cnt,:});
% 	% look for 1st word MSG and 3rd word led
% 	if strcmp(word_list{1}, 'MSG') && length(word_list)>4 && strcmp(word_list{3}, 'led')
% 		led_msg_cnt = led_msg_cnt + 1;
% 		led_time(led_msg_cnt) = str2double(word_list{2});
% 		led_num(led_msg_cnt) = str2double(word_list{4});
% 		led_on_off{led_msg_cnt} = word_list{5};
% 	end % led msg
% end 
% 
% if led_msg_cnt > 0
% 	handles.led_data_tbl = table(led_time', led_num', led_on_off', ...
% 		'VariableNames', {'abs_time', 'num', 'on_off'});
% end
% if exist('led_dist_tbl', 'var')
% 	handles.led_data_tbl = join(handles.led_data_tbl, led_dist_tbl);
% end


% target time vector is same as eye_data
handles.target_data.t = (1:handles.eye_data.numsamps)/handles.eye_data.samp_freq;
handles.target_data.x = nan(size(handles.target_data.t));
handles.target_data.y = nan(size(handles.target_data.t));

ipd = handles.led_results.testresults.ipd;
t_start = handles.led_results.testresults.startPTB;
r_cal_offset = atan2d(-ipd/2,550);

% turn led results.tgtpos struct into target lines
for cnt = 1:length(handles.led_results.tgtpos)
	% if led is on, determine the eye angle to display
	if handles.led_results.tgtpos(cnt).led > 0
		x_led = handles.led_results.tgtpos(cnt).distance * tand(handles.led_results.tgtpos(cnt).angle);
		y_led = handles.led_results.tgtpos(cnt).distance;
		x_right = atan2d((x_led-ipd/2),y_led) - r_cal_offset;
	else % led is off don't show any number
		x_right = nan;
	end
	mask = handles.target_data.t >= (handles.led_results.tgtpos(cnt).when-t_start)/1000;
	handles.target_data.x(mask) = x_right;
end
% draw the target lines
axes(handles.axes_eye)
handles.line_target_x = line(handles.target_data.t, handles.target_data.x, 'Tag', 'line_target_x', 'Color', 'b');
return % get_led_data