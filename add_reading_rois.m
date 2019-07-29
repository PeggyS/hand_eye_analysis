function handles = add_pict_diff_roi_grid(handles)
axes(handles.axes_video_overlay)

% the '_#' in the file name to determine the default image name
tmp = regexp(handles.bin_filename, '_\d+.bin', 'match');
underscore_num = strrep(tmp{1}, '.bin', '');
num = strrep(underscore_num, '_', '');
% find od, os, or ou in path
tmp = regexpi(handles.bin_filename, '(od)|(os)|(ou)\', 'match');
eye = lower(tmp{1});

roi_fname = [eye num '_rois.csv'];
[pathstr, ~, ~] = fileparts(handles.bin_filename);




if strcmpi(reply, 'y')
	% request grid file
	disp('Select grid file (*.csv)')
	[filename, pathname] = uigetfile('*.csv', 'Pick a grid file');
    if isequal(filename,0) || isequal(pathname,0)
       disp('User pressed cancel')
		return
	else
		handles.grid_file = fullfile(pathname, filename);
       disp(['Grid file: ', handles.grid_file])
    end
	% create grid
	handles = create_grid(handles);
else
	%create default pict_diff grid
	handles = default_grid(handles);
end

return

