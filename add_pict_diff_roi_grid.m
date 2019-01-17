function handles = add_pict_diff_roi_grid(handles)
axes(handles.axes_video_overlay)

% ask for grid file or use default
reply = input('Choose grid file? Y/N [Y]:','s');
if isempty(reply)
  reply = 'Y';
end
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

