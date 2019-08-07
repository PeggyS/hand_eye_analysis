function handles = add_reading_rois(handles)
axes(handles.axes_video_overlay)

% the '_#' in the file name to determine the default image name
tmp = regexp(handles.bin_filename, '_\d+.bin', 'match');
underscore_num = strrep(tmp{1}, '.bin', '');
num = strrep(underscore_num, '_', '');
% find od, os, or ou in path
tmp = regexpi(handles.bin_filename, '(od)|(os)|(ou)/', 'match');
eye = strrep(lower(tmp{1}), '/', '');

roi_fname = [eye num '_rois.csv'];
[pathstr, ~, ~] = fileparts(handles.bin_filename);

% create default roi filename from bin_filename

tmp = regexpi(handles.bin_filename, '/t\d(?<eye>(OD|OU|OS)).*(?<tr_num>\d).bin', 'names');
if ~isempty(tmp)
	roi_fname = [tmp.eye tmp.tr_num '_rois.csv'];
end
% ask for roi file or use default
reply = input(['Reading page ROI file = ' roi_fname '? Y/N [Y]:'],'s');
if isempty(reply)
  reply = 'Y';
end

if strcmpi(reply, 'y')
	[~, grid_fname] = system(['mdfind -onlyin ../../../ -name ' roi_fname]);
	[pn, fn] = findfilepath(roi_fname, '../../../');
	grid_fname = fullfile(pn,fn);
end

if strcmpi(reply, 'n') || ~exist(grid_fname, 'file')
	% request grid file
	disp('Select reading page roi file (*.csv)')
	[filename, pathname] = uigetfile('*.csv', 'Pick a roi file');
	if isequal(filename,0) || isequal(pathname,0)
		disp('User pressed cancel')
		return
	else
		grid_fname = fullfile(pathname, filename);
	end
end


handles.grid_file = grid_fname;
disp(['Grid file: ', handles.grid_file])

% create rois
handles = draw_reading_rois(handles);

return

