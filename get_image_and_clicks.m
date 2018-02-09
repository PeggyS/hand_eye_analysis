function handles = get_image_and_clicks(handles)
% get the "Click_data.txt" file. It contains the image file name and the 
% click times and positions

disp('Choose CLICK_DATA.txt file ...')
[fnSave, pnSave] = uigetfile({'*.txt'}, 'Choose CLICK_DATA.txt file ...');
if isequal(fnSave,0) || isequal(pnSave,0)
   disp('no  file chosen ... ')
   return
end
handles.click_filename = fullfile(pnSave, fnSave);

% parse the info in the file

% read in
handles.click_data_tbl = readtable(handles.click_filename,'delimiter','\t');

% get the image 
if exist(fullfile(pnSave, char(handles.click_data_tbl.image(1))),'file')
	handles.im_data = imread(fullfile(pnSave, char(handles.click_data_tbl.image(1))));
else

	% look in this folder and in parent folders
	if exist(strrep(char(handles.click_data_tbl.image(1)), '_', ' '),'file')
		handles.im_data = imread(strrep(char(handles.click_data_tbl.image(1)), '_', ' '));
	else
		% go up 2 folders and look for the image in 'picture_diff' folder
		cur_dir = pwd;
		cd(['..' filesep '..'])
		if exist('picture_diff','dir')
			cd 'picture_diff'
			if exist(strrep(char(handles.click_data_tbl.image(1)), '_', ' '),'file')
				handles.im_data = imread(strrep(char(handles.click_data_tbl.image(1)), '_', ' '));
			end
		else
			% request file location
			disp('choose image file ...')
			[fnImg, pnImg] = uigetfile({'*.*'}, 'Choose image file ...');
			if isequal(fnImg,0) || isequal(pnImg,0)
				disp('no image file')
				return
			else
				handles.im_data = imread(fullfile(pnImg,fnImg));
			end
		end
		cd(cur_dir)
	end
end

% read in the msg file
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
% read in
msgs = importdata(msg_fname, char(13)); % each line is read in as a cell

% add info to click_data_tbl to indicate the times relative to 
% the start of data collection instead of the display's appearance

% find the first SYNCTIME MSG - this is the time when the image display begins
for line_cnt = 1:length(msgs)

	word_list = split(msgs{line_cnt,:});
	if strcmp(word_list{1}, 'MSG') && length(word_list)>3 && strcmp(word_list{4}, 'SYNCTIME')
		t_str = regexp(word_list{2}, '\d*', 'match'); % the millisecond number after 'MSG'
		t2_str = regexp(word_list{3}, '\d*', 'match'); % the additional milliseconds to add to the first number to get the actual time of the event
		t_disp_begin = str2double(t_str{1}) + str2double(t2_str{1});
		break
	end % found synctime	
end
assert(exist('t_disp_begin', 'var')==1, 'did not find SYNCTIME MSG indicating the beginning time of the image display' )

line_ind = line_cnt;
% continue reading from the found synctime
for line_cnt = line_ind:length(msgs)
	word_list = split(msgs{line_cnt,:});
	% look for MOUSE_CLICK MSG with the coordinates
% 		if line_cnt > 182
% 		keyboard
% 	end
	if strcmp(word_list{1}, 'MSG') && length(word_list)>5 && strcmp(word_list{4}, 'MOUSE_CLICK')
		x_str = regexp(word_list{5}, '\d+', 'match');
		y_str = regexp(word_list{6}, '\d+', 'match');
		click_coord_str = ['['  x_str{:}  ', ' y_str{:}  ']']; 
		tbl_row = strcmp(handles.click_data_tbl.CLICK_COORDINATES, click_coord_str);
		handles.click_data_tbl.abs_click_time(tbl_row) = str2double(word_list{2});
	end % found mouse_click
end 

return