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

% try to read in the image file
if isempty(handles.click_data_tbl)
	reply = input('There are no clicks recorded. Is there an image to display? y/n [y]:','s');
	if isempty(reply)
		reply = 'y';
	end
	if strcmp(reply, 'y')
		% request file location
		disp('choose image file ...')
		[fnImg, pnImg] = uigetfile({'*.*'}, 'Choose image file ...');
		if isequal(fnImg,0) || isequal(pnImg,0)
			disp('no image file')
			return
		else
			handles.im_filename = fullfile(pnImg,fnImg);
			handles.im_data = imread(fullfile(pnImg,fnImg));
		end
	else
		% display a gray blank image
		handles.im_filename = 'gray.png';
		handles.im_data = imread('gray.png');
	end
end

found_img = false;
% multiple images in click_data file
if any(strcmp(handles.click_data_tbl.Properties.VariableNames, 'trial_sequence_num'))
	% get the trial number from the bin_filename
	tmp = regexp(handles.bin_filename, '_\d+.bin', 'match');
	tmp = strrep(tmp, '_', '');
	tmp = strrep(tmp, '.bin', '');
	trial_num = str2double(tmp);
	% find the table rows for this trial num
	row_inds = find(handles.click_data_tbl.trial_sequence_num == trial_num);
	if ~isempty(row_inds)
		click_tbl_row = row_inds(1);
	else
		disp('There are no mouse clicks for this trial. Cannot determine the image to display.')
		click_tbl_row = 1;
		reply = input('There are no clicks recorded. Is there an image to display? y/n [y]:','s');
		if isempty(reply)
			reply = 'y';
		end
		if strcmp(reply, 'y')
			% request file location
			disp('choose image file ...')
			[fnImg, pnImg] = uigetfile({'*.*'}, 'Choose image file ...');
			if isequal(fnImg,0) || isequal(pnImg,0)
				disp('no image file')
				% display a gray blank image
				handles.im_filename = 'gray.png';
				handles.im_data = imread('gray.png');
			else
				handles.im_filename = fullfile(pnImg,fnImg);
				handles.im_data = imread(fullfile(pnImg,fnImg));
			end
		else
			% display a gray blank image
			handles.im_filename = 'gray.png';
			handles.im_data = imread('gray.png');
		end
		found_img = true;
	end
else
	click_tbl_row = 1; % just get the first row in the file
end


if ~found_img
	img_fname = char(handles.click_data_tbl.image(click_tbl_row));
	if exist(fullfile(pnSave, img_fname),'file')
		handles.im_filename = fullfile(pnSave,img_fname);
		handles.im_data = imread(handles.im_filename);
	else
		
		% look in this folder
		if exist(strrep(img_fname, '_', ' '),'file')
			handles.im_filename = fullfile(pwd,strrep(img_fname), '_', ' ');
			handles.im_data = imread(handles.im_filename);
% 			found_img = true;
		else
			% go up 3 folders and look for the image
			[pathname,filename] = findfilepath(img_fname, '../../..');
			if isempty(pathname)
				% request file location
				disp('choose image file ...')
				[fnImg, pnImg] = uigetfile({'*.*'}, 'Choose image file ...');
				if isequal(fnImg,0) || isequal(pnImg,0)
					disp('no image file')
					return
				else
					handles.im_filename = fullfile(pnImg,fnImg);
					handles.im_data = imread(handles.im_filename);
				end
			else
				handles.im_filename = fullfile(pathname,filename);
				handles.im_data = imread(handles.im_filename);
			end
% 			cur_dir = pwd;
% 			cd(['..'])
% 			if exist('picture_diff','dir')
% 				cd 'picture_diff'
% 				if exist(strrep(char(handles.click_data_tbl.image(click_tbl_row)), '_', ' '),'file')
% 					handles.im_filename = fullfile(pwd,strrep(char(handles.click_data_tbl.image(click_tbl_row)), '_', ' '));
% 					handles.im_data = imread(handles.im_filename);
% 					found_img = true;
% 				elseif exist(char(handles.click_data_tbl.image(click_tbl_row)),'file')
% 					handles.im_filename = fullfile(pwd,char(handles.click_data_tbl.image(click_tbl_row)));
% 					handles.im_data = imread(handles.im_filename);
% 					found_img = true;
% 				end
% 			else
% 				cd(['..'])
% 				if exist('picture_diff','dir')
% 					cd 'picture_diff'
% 					if exist(strrep(char(handles.click_data_tbl.image(click_tbl_row)), '_', ' '),'file')
% 						handles.im_filename = fullfile(pwd,strrep(char(handles.click_data_tbl.image(click_tbl_row)), '_', ' '));
% 						handles.im_data = imread(handles.im_filename);
% 						found_img = true;
% 					elseif exist(char(handles.click_data_tbl.image(click_tbl_row)),'file')
% 						handles.im_filename = fullfile(pwd,char(handles.click_data_tbl.image(click_tbl_row)));
% 						handles.im_data = imread(handles.im_filename);
% 						found_img = true;
% 					end
% 				else
% 					% request file location
% 					disp(['choose image file ' char(handles.click_data_tbl.image(click_tbl_row))])
% 					[fnImg, pnImg] = uigetfile({'*.*'}, 'Choose image file ...');
% 					if isequal(fnImg,0) || isequal(pnImg,0)
% 						disp('no image file')
% 						return
% 					else
% 						handles.im_filename = fullfile(pnImg,fnImg);
% 						handles.im_data = imread(handles.im_filename);
% 						found_img = true;
% 					end
% 				end
% 			end
% 			cd(cur_dir)

% 			if ~found_img
% 				% still not finding the image ...
% 				disp(['Choose image file: ' char(handles.click_data_tbl.image(click_tbl_row)) ])
% 				[fnImg, pnImg] = uigetfile({'*.*'}, 'Choose image file ...');
% 				if isequal(fnImg,0) || isequal(pnImg,0)
% 					disp('no image file - will display gray image')
% 					handles.im_filename = 'gray.png';
% 					handles.im_data = imread('gray.png');
% 				else
% 					handles.im_filename = fullfile(pnImg,fnImg);
% 					handles.im_data = imread(handles.im_filename);
% 				end
% 			end
		end
	end
end
if isfield(handles, 'im_filename')
	disp(['image file: ' handles.im_filename])
	% with an image file, now look for a priors image file
	[~, prior_img_file, ~] = fileparts(handles.im_filename);
	prior_img_file = [prior_img_file, '_prior.png'];
	% go up 3 folders and look for the image
	[pathname,filename] = findfilepath(prior_img_file, '../../..');
	if isempty(pathname)
		% request file location
		disp('choose priors file ...')
		[fnImg, pnImg] = uigetfile({'*.*'}, 'Choose priors file ...');
		if isequal(fnImg,0) || isequal(pnImg,0)
			disp('no priors file')
		else
			handles.im_prior_filename = fullfile(pnImg,fnImg);
			handles.im_prior_data = imread(handles.im_prior_filename);
			disp(['priors: ' handles.im_prior_filename])
			handles.chkbxPrior.Visible = 'on';
		end
	else
		handles.im_prior_filename = fullfile(pathname,filename);
		handles.im_prior_data = imread(handles.im_prior_filename);
		disp(['priors: ' handles.im_prior_filename])
		handles.chkbxPrior.Visible = 'on';
	end
	
end


% read in the msg file
% the msg file name
% msg_fname = strrep(handles.bin_filename, '.bin', '_msgs.asc');
msg_fname = regexprep(handles.bin_filename, '(_\d+.bin)|(.bin)', '_msgs.asc');
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
lastwarn('')  % clear last warning msg
msgs = importdata(msg_fname, char(13)); % each line is read in as a cell
% check for a new warning
[warnMsg, warnId] = lastwarn;
if ~isempty(warnMsg)
	disp(['warning at line 217 - reading in msg_fname: ' msg_fname])
end

% add info to click_data_tbl to indicate the times relative to 
% the start of data collection instead of the display's appearance
sync_found = false;
for line_cnt_trial = 1:length(msgs)
% find the msg "MSG	929110 TRIALID 0" corresponding to this trial	
	word_list = split(msgs{line_cnt_trial,:});
	if strcmp(word_list{1}, 'MSG') && length(word_list)>3 && strcmp(word_list{3}, 'TRIALID') && ...
			strcmp(word_list{4}, num2str(trial_num-1))
		for line_cnt = line_cnt_trial+1:length(msgs)
			% find the first SYNCTIME MSG - this is the time when the image display begins
			word_list = split(msgs{line_cnt,:});
			if strcmp(word_list{1}, 'MSG') && length(word_list)>3 && strcmp(word_list{4}, 'SYNCTIME')
				t_str = regexp(word_list{2}, '\d*', 'match'); % the millisecond number after 'MSG'
				t2_str = regexp(word_list{3}, '\d*', 'match'); % the additional milliseconds to add to the first number to get the actual time of the event
				t_disp_begin = str2double(t_str{1}) + str2double(t2_str{1});
				sync_found = true;
				break
			end % found synctime
		end
		if sync_found
			break
		end
	end % found trial num
end
assert(exist('t_disp_begin', 'var')==1, 'did not find SYNCTIME MSG indicating the beginning time of the image display' )
% save the time the image appears in the each row of the table
handles.click_data_tbl.time_display_begin = repmat(t_disp_begin, height(handles.click_data_tbl), 1);


line_ind = line_cnt_trial;
tbl_row = 0;  % if coordinates are not in the msg file after MOUSE_CLICK, then assume that they
					% appear in cronological order. This is to accomodate
					% older versions of data recording.
click_cnt = 0;
% continue reading from the found synctime
for line_cnt = line_ind:length(msgs)
	word_list = split(msgs{line_cnt,:});
	% look for MOUSE_CLICK MSG with the coordinates
% 		if line_cnt > 182
% 		keyboard
% 	end
	
	if strcmp(word_list{1}, 'MSG') && length(word_list)>3 && strcmp(word_list{4}, 'MOUSE_CLICK')
		click_cnt = click_cnt+1;
		if length(word_list)>5
			x_str = regexp(word_list{5}, '\d+', 'match');
			y_str = regexp(word_list{6}, '\d+', 'match');
			click_coord_str = ['['  x_str{:}  ', ' y_str{:}  ']']; 
			tbl_row = strcmp(handles.click_data_tbl.CLICK_COORDINATES, click_coord_str);
			handles.click_data_tbl.abs_click_time(tbl_row) = str2double(word_list{2});
		else % assuming clicks are in order of saved in the click_data.txt file and in message file
			% find the click_cnt row with trial_num == click_data_tbl.trial_sequence_num
			if any(strcmp(handles.click_data_tbl.Properties.VariableNames, 'trial_sequence_num'))
				found_inds = find(handles.click_data_tbl.trial_sequence_num == trial_num, click_cnt);
				if length(found_inds) >= click_cnt
					% if first found ind is for a row with CLICK_TIME = 0,
					% then use the table row + 1. This is because the mult
					% pict diff has an addition row in the clickdata table
					% for the initial picture being displayed, not a mouse
					% click. Its click_time = 0.
					if handles.click_data_tbl.CLICK_TIME(found_inds(1)) == 0
						tbl_row = found_inds(click_cnt)+1;
					else
						tbl_row = found_inds(click_cnt);
					end
					handles.click_data_tbl.abs_click_time(tbl_row) = str2double(word_list{2});
				else
					break
				end
			else
%  			keyboard
				tbl_row = tbl_row+1;
				handles.click_data_tbl.abs_click_time(tbl_row) = str2double(word_list{2});
			end
		end
	end % found mouse_click
end 

return