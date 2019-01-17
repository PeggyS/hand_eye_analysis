function handles = default_grid(handles)

% horizontal lines
y_line_incr = diff(handles.axes_video_overlay.YLim)/5;
y_line_vals = handles.axes_video_overlay.YLim(2) : -y_line_incr : handles.axes_video_overlay.YLim(1);
for cnt = 1:length(y_line_vals)
	hl = line(handles.axes_video_overlay.XLim, [y_line_vals(cnt), y_line_vals(cnt)]);
	if cnt > 1
		hl.Tag = ['line_grid_bottom_row_' num2str(cnt-1)];
	end
end

% left pic vertical lines
xright = -0.5;
x_line_incr = (xright - handles.axes_video_overlay.XLim(1))/5;
x_line_vals = handles.axes_video_overlay.XLim(1) : x_line_incr : xright;
for cnt = 1:length(x_line_vals)
	hl = line([x_line_vals(cnt), x_line_vals(cnt)], handles.axes_video_overlay.YLim);
	if cnt > 1
		hl.Tag = ['line_left_pic_grid_right_col_' num2str(cnt-1)];
	end
end
% right pic vertical lines
xleft = 0.5;
x_line_incr = (handles.axes_video_overlay.XLim(2)-xleft)/5;
x_line_vals = xleft : x_line_incr :  handles.axes_video_overlay.XLim(2);
for cnt = 1:length(x_line_vals)
	hl = line([x_line_vals(cnt), x_line_vals(cnt)], handles.axes_video_overlay.YLim);
	if cnt > 1
		hl.Tag = ['line_right_pic_grid_right_col_' num2str(cnt-1)];
	end
end