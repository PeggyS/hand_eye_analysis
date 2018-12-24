function out_data = apply_vergence_cal(in_data, cal_info, display_flag)
% use the vergence calibration info from vergence_cal_gui to calibrate the
% data and optionally view the original and calibrated data
% 
%
% example: rh_calibrated = apply_vergence_cal(rh, cal_info, false) will
% calibrate the rh data and return the calibrated data.
%
% example: lh_cal = apply_vergence_cal(lh, cal_info, true) will calibrate
% lh and display a figure showin the original data (blue) and the
% calibrated data (red)

if display_flag
	figure
	plot(1:length(in_data), in_data);
	ylabel('Eye Pos (°)')
end

% zero offset
zero_ind = find(cal_info.target_angle == 0);
center_offset = - cal_info.eyelink_gaze_angle(zero_ind) + cal_info.eye_in_head_angle(zero_ind);
out_data = in_data + center_offset;

if display_flag
	hl_out = line(1:length(out_data),out_data,'color','r');
	chng_data=out_data;
	chng_data=nan(size(out_data));
	h_chng = line(1:length(chng_data),chng_data, 'color', 'g');
end

% zero centered eyelink gaze data
el_gaze_offset = cal_info.eyelink_gaze_angle(zero_ind);
shift_data = in_data - el_gaze_offset;

% find positive target angles
pos_inds = find(cal_info.target_angle > 0);

[target_angles, t_inds_order] = sort(cal_info.target_angle(pos_inds));
t_inds = pos_inds(t_inds_order);	% index into cal_info vectors in the same order as target_angles

% prev_ind = zero_ind;
% prev_angle = center_offset;
% for a_cnt = 1:length(target_angles)-1

% first scale area (usually 10deg target)
scale_factor = (cal_info.eye_in_head_angle(t_inds(1)) - cal_info.eye_in_head_angle(zero_ind)) / ...
	(cal_info.eyelink_gaze_angle(t_inds(1)) - cal_info.eyelink_gaze_angle(zero_ind));
% 		(cal_info.eyelink_gaze_angle(t_inds(a_cnt)) - el_gaze_offset);

% the data being scaled
msk = out_data > cal_info.eye_in_head_angle(zero_ind) & ...
	out_data <=  cal_info.eyelink_gaze_angle(t_inds(1)) + center_offset;
if display_flag
	chng_data=nan(size(out_data));
	chng_data(msk) = out_data(msk);
	h_chng.YData = chng_data;
end
% scale the data
shift_data = in_data - cal_info.eyelink_gaze_angle(zero_ind);
out_data(msk) = shift_data(msk) * scale_factor + cal_info.eye_in_head_angle(zero_ind);
if display_flag
	chng_data(msk) = out_data(msk);
	h_chng.YData = chng_data;
	hl_out.YData = out_data;
end

% second scale area (usually 20deg target)
scale_factor = (cal_info.eye_in_head_angle(t_inds(2)) - cal_info.eye_in_head_angle(t_inds(1))) / ...
	(cal_info.eyelink_gaze_angle(t_inds(2)) - cal_info.eyelink_gaze_angle(t_inds(1)));

% data being changed
msk = out_data > cal_info.eye_in_head_angle(t_inds(1));
if display_flag
	chng_data=nan(size(out_data));
	chng_data(msk) = out_data(msk);
	h_chng.YData = chng_data;
end
% scale the data
out_data(msk) = (out_data(msk)-cal_info.eyelink_gaze_angle(t_inds(1))-center_offset) * scale_factor + ...
	cal_info.eye_in_head_angle(t_inds(1));
if display_flag
	hl_out.YData = out_data;
end


% find negative target angles
neg_inds = find(cal_info.target_angle < 0);

[target_angles, t_inds_order] = sort(cal_info.target_angle(neg_inds), 'descend');
t_inds = neg_inds(t_inds_order);	% index into cal_info vectors in the same order as target_angles


% 1st neg (-10deg)
scale_factor = (cal_info.eye_in_head_angle(t_inds(1)) - cal_info.eye_in_head_angle(zero_ind)) / ...
	(cal_info.eyelink_gaze_angle(t_inds(1)) - cal_info.eyelink_gaze_angle(zero_ind));

% data being scaled
msk = out_data < cal_info.eye_in_head_angle(zero_ind) ...
	& out_data >=  cal_info.eyelink_gaze_angle(t_inds(1)) + center_offset;
if display_flag
	chng_data=nan(size(out_data));
	chng_data(msk) = out_data(msk);
	h_chng.YData = chng_data;
end
% scale the data
out_data(msk) = shift_data(msk) * scale_factor + cal_info.eye_in_head_angle(zero_ind);
if display_flag
	hl_out.YData = out_data;
end


% second (-20deg) 	
scale_factor = (cal_info.eye_in_head_angle(t_inds(2)) - cal_info.eye_in_head_angle(t_inds(1))) / ...
	(cal_info.eyelink_gaze_angle(t_inds(2)) - cal_info.eyelink_gaze_angle(t_inds(1)));

% data being scaled
msk = out_data < cal_info.eye_in_head_angle(t_inds(1));
if display_flag
	chng_data=nan(size(out_data));
	chng_data(msk) = out_data(msk);
	h_chng.YData = chng_data;
end

% scale the data
out_data(msk) = (out_data(msk)-cal_info.eyelink_gaze_angle(t_inds(1))-center_offset) * scale_factor + ...
	cal_info.eye_in_head_angle(t_inds(1));
if display_flag
	hl_out.YData = out_data;

	chng_data=nan(size(out_data));
	h_chng.YData = chng_data;
	zoomtool
end

% 
% if length(pos_inds==1)
% 	scale_factor = (cal_info.eye_in_head_angle(pos_inds) - cal_info.eye_in_head_angle(zero_ind)) / ...
% 		(cal_info.eyelink_gaze_angle(pos_inds) - el_gaze_offset);	
% end	 
% out_data(out_data > center_offset) = shift_data(out_data > center_offset) * scale_factor + ...
% 	cal_info.eye_in_head_angle(zero_ind);