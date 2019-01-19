function handles = create_grid(handles)

tbl = readtable(handles.grid_file);

xlims = handles.axes_video_overlay.XLim;
ylims = handles.axes_video_overlay.YLim;
		
% horizontal lines
h_line_pixels = unique([tbl.top;tbl.bottom]);
h_line_deg = ylims(2) - h_line_pixels/30; 

for cnt = 1:length(h_line_deg)
	hl = line(xlims, [h_line_deg(cnt), h_line_deg(cnt)]);
	if cnt > 1
		hl.Tag = ['line_grid_bottom_row_' num2str(cnt-1)];
	end
end

% vertical lines
v_line_pixels = unique([tbl.left;tbl.right]);
v_line_deg = v_line_pixels/30 - xlims(2);
for cnt = 1:length(v_line_deg)
	hl = line([v_line_deg(cnt), v_line_deg(cnt)], ylims);
	if cnt > 1
		hl.Tag = ['line_grid_right_col_' num2str(cnt-1)];
	end
end
