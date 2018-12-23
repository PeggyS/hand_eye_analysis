function out_data = apply_vergence_cal(in_data, cal_info)

figure
plot(1:length(in_data), in_data);

% zero offset
zero_ind = find(cal_info.target_angle == 0);
center_offset = - cal_info.eyelink_gaze_angle(zero_ind) + cal_info.eye_in_head_angle(zero_ind);
out_data = in_data + center_offset;

hl_out = line(1:length(out_data),out_data,'color','r');
chng_data=out_data;
chng_data=nan(size(out_data));
h_chng = line(1:length(chng_data),chng_data, 'color', 'g');

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
chng_data=nan(size(out_data));
chng_data(msk) = out_data(msk);
h_chng.YData = chng_data;

% scale the data
shift_data = in_data - cal_info.eyelink_gaze_angle(zero_ind);
out_data(msk) = shift_data(msk) * scale_factor + cal_info.eye_in_head_angle(zero_ind);
chng_data(msk) = out_data(msk);
h_chng.YData = chng_data;
hl_out.YData = out_data;


% second scale area (usually 20deg target)
scale_factor = (cal_info.eye_in_head_angle(t_inds(2)) - cal_info.eye_in_head_angle(t_inds(1))) / ...
	(cal_info.eyelink_gaze_angle(t_inds(2)) - cal_info.eyelink_gaze_angle(t_inds(1)));

% data being changed
msk = out_data > cal_info.eye_in_head_angle(t_inds(1));
chng_data=nan(size(out_data));
chng_data(msk) = out_data(msk);
h_chng.YData = chng_data;
% scale the data
out_data(msk) = (out_data(msk)-cal_info.eyelink_gaze_angle(t_inds(1))-center_offset) * scale_factor + ...
	cal_info.eye_in_head_angle(t_inds(1));
hl_out.YData = out_data;


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
chng_data=nan(size(out_data));
chng_data(msk) = out_data(msk);
h_chng.YData = chng_data;

% scale the data
out_data(msk) = shift_data(msk) * scale_factor + cal_info.eye_in_head_angle(zero_ind);
hl_out.YData = out_data;


% second (-20deg) 	
scale_factor = (cal_info.eye_in_head_angle(t_inds(2)) - cal_info.eye_in_head_angle(t_inds(1))) / ...
	(cal_info.eyelink_gaze_angle(t_inds(2)) - cal_info.eyelink_gaze_angle(t_inds(1)));

% data being scaled
msk = out_data < cal_info.eye_in_head_angle(t_inds(1));
chng_data=nan(size(out_data));
chng_data(msk) = out_data(msk);
h_chng.YData = chng_data;

% scale the data
out_data(msk) = (out_data(msk)-cal_info.eye_in_head_angle(t_inds(1))-center_offset) * scale_factor + ...
	cal_info.eye_in_head_angle(t_inds(1));
hl_out.YData = out_data;
zoomtool


% 
% if length(pos_inds==1)
% 	scale_factor = (cal_info.eye_in_head_angle(pos_inds) - cal_info.eye_in_head_angle(zero_ind)) / ...
% 		(cal_info.eyelink_gaze_angle(pos_inds) - el_gaze_offset);	
% end	 
% out_data(out_data > center_offset) = shift_data(out_data > center_offset) * scale_factor + ...
% 	cal_info.eye_in_head_angle(zero_ind);