function handles = draw_reading_rois(handles)

roi_tbl = readtable(handles.grid_file);

% draw rois on handles.axes_video_overlay (xlims: 0-1024; ylims 0-768)
% handles.axes_video origin = upper left

for row = 1:height(roi_tbl)
	x = [roi_tbl.left(row) roi_tbl.right(row) roi_tbl.right(row) roi_tbl.left(row) roi_tbl.left(row)];
	y = [roi_tbl.top(row) roi_tbl.top(row) roi_tbl.bottom(row) roi_tbl.bottom(row) roi_tbl.top(row) ];
	line(handles.axes_video, x, y, 'Color', [1 0 0]);
end