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

