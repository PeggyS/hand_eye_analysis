function roi = find_roi_from_file(handles, x_eye, y_eye, t_eye)

roi = [];

xlims = handles.axes_video_overlay.XLim;
ylims = handles.axes_video_overlay.YLim;

tbl = readtable(handles.grid_file);


h_eye_pixel = (x_eye + xlims(2)) * 30;
v_eye_pixel = (ylims(2) - y_eye) * 30;

tbl_rows = tbl(tbl.left<=h_eye_pixel & tbl.right>=h_eye_pixel ...
	& tbl.top<=v_eye_pixel & tbl.bottom>=v_eye_pixel,:);

if isempty(tbl_rows)
	% beep
	fprintf('t = %g: did not find pixel (h,v) = (%g, %g) in %s\n', ...
		t_eye, h_eye_pixel, v_eye_pixel, handles.grid_file)
	return
end
if height(tbl_rows) > 1
	fprintf('found pixel (h,v) = (%g, %g) in %d rows of %s\n', ...
		h_eye_pixel, v_eye_pixel, height(tbl_rows), handles.grid_file)
	disp(tbl_rows)
end

roi = tbl_rows.roi(1);