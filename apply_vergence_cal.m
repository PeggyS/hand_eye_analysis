function out_data = apply_vergence_cal(in_data, cal_info)


% zero offset
ind = find(cal_info.target_angle == 0);
center_offset = - cal_info.eyelink_gaze_angle(ind) + cal_info.eye_in_head_angle(ind);
out_data = in_data + center_offset;

% zero centered eyelink gaze data
el_gaze_offset = cal_info.eyelink_gaze_angle(ind);
shift_data = in_data - el_gaze_offset;

% find positive target angles
pos_inds = find(cal_info.target_angle > 0);

if length(pos_inds==1)
	scale_factor = (cal_info.eye_in_head_angle(pos_inds) - center_offset) / ...
		(cal_info.eyelink_gaze_angle(pos_inds) - el_gaze_offset);	
end	 
out_data(out_data > center_offset) = shift_data(out_data > center_offset) * scale_factor + ...
	cal_info.eye_in_head_angle(ind);