function new_sacclist = compute_drift(sacclist, h_pos, v_pos, samp_freq)
% compute the intersaccade drift parameters - copying algorithm from 'AnalyzeDrift.m' 

% sacclist is a struct with existing saccade info. We will add new fields
% to it for this function's output.

new_sacclist = sacclist;
new_sacclist.as_mean_ind = nan(size(sacclist.start_ind));
new_sacclist.as_median_horiz = nan(size(sacclist.start_ind));
new_sacclist.as_mean_horiz = nan(size(sacclist.start_ind));
new_sacclist.as_var_horiz = nan(size(sacclist.start_ind));
new_sacclist.as_std_horiz = nan(size(sacclist.start_ind));
new_sacclist.as_median_vert = nan(size(sacclist.start_ind));
new_sacclist.as_mean_vert = nan(size(sacclist.start_ind));
new_sacclist.as_var_vert = nan(size(sacclist.start_ind));
new_sacclist.as_std_vert = nan(size(sacclist.start_ind));
new_sacclist.as_median_norm_vel = nan(size(sacclist.start_ind));
new_sacclist.as_mean_norm_vel = nan(size(sacclist.start_ind));
new_sacclist.as_var_norm_vel = nan(size(sacclist.start_ind));
new_sacclist.as_std_norm_vel = nan(size(sacclist.start_ind));
new_sacclist.as_median_norm_pos = nan(size(sacclist.start_ind));
new_sacclist.as_mean_norm_pos = nan(size(sacclist.start_ind));
new_sacclist.as_var_norm_pos = nan(size(sacclist.start_ind));
new_sacclist.as_std_norm_pos = nan(size(sacclist.start_ind));

% norm pos
norm_pos = sqrt(h_pos.^2 + v_pos.^2);

% velocity
h_vel = diff(h_pos)*samp_freq;
v_vel = diff(v_pos)*samp_freq;

% filter the velocity
h_vel_filt = sgolayfilt(h_vel, 3, 11);
v_vel_filt = sgolayfilt(v_vel, 3, 11);
norm_vel = sqrt(h_vel_filt.^2 + v_vel_filt.^2);

for sacc_num = 1:length(sacclist.start_ind)-1
	start_ind = sacclist.end_ind(sacc_num); % start of the drift after this saccade
	end_ind = sacclist.start_ind(sacc_num+1); % end of the drift
	new_sacclist.as_mean_ind(sacc_num) = mean([start_ind end_ind]);
	
	if ~any(isnan(h_vel_filt(start_ind:end_ind)))
		new_sacclist.as_median_horiz(sacc_num) = median(h_vel_filt(start_ind:end_ind));
		new_sacclist.as_mean_horiz(sacc_num) = mean(h_vel_filt(start_ind:end_ind));
		new_sacclist.as_var_horiz(sacc_num) = var(h_vel_filt(start_ind:end_ind));
		new_sacclist.as_std_horiz(sacc_num) = std(h_vel_filt(start_ind:end_ind));
	end
	if ~any(isnan(v_vel_filt(start_ind:end_ind)))
		new_sacclist.as_median_vert(sacc_num) = median(v_vel_filt(start_ind:end_ind));
		new_sacclist.as_mean_vert(sacc_num) = mean(v_vel_filt(start_ind:end_ind));
		new_sacclist.as_var_vert(sacc_num) = var(v_vel_filt(start_ind:end_ind));
		new_sacclist.as_std_vert(sacc_num) = std(v_vel_filt(start_ind:end_ind));
	end
	if ~any(isnan(norm_vel(start_ind:end_ind)))
		new_sacclist.as_median_norm_vel(sacc_num) = median(norm_vel(start_ind:end_ind));
		new_sacclist.as_mean_norm_vel(sacc_num) = mean(norm_vel(start_ind:end_ind));
		new_sacclist.as_var_norm_vel(sacc_num) = var(norm_vel(start_ind:end_ind));
		new_sacclist.as_std_norm_vel(sacc_num) = std(norm_vel(start_ind:end_ind));
	end
	if ~any(isnan(norm_pos(start_ind:end_ind)))
		new_sacclist.as_median_norm_pos(sacc_num) = median(norm_pos(start_ind:end_ind));
		new_sacclist.as_mean_norm_pos(sacc_num) = mean(norm_pos(start_ind:end_ind));
		new_sacclist.as_var_norm_pos(sacc_num) = var(norm_pos(start_ind:end_ind));
		new_sacclist.as_std_norm_pos(sacc_num) = std(norm_pos(start_ind:end_ind));
	end
end % each saccade in sacclist





