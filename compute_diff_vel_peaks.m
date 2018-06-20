function new_sacclist = compute_diff_vel_peaks(sacclist, h_pos, v_pos, samp_freq)
% compute the horizonal and vertical components of velocity using
% h_vel = abs(diff(h_pos)). Compute horizontal and vertical velocities
% separately. Look for max values during the saccades (h & v separately),
% then compute a 'combined' velocity from those h & v peaks.

% sacclist is a struct with existing saccade info. We will add new fields
% to it for this function's output.

new_sacclist = sacclist;

h_vel = diff(h_pos)*samp_freq;
v_vel = diff(v_pos)*samp_freq;

for sacc_num = 1:length(sacclist.start_ind)
	start_ind = sacclist.start_ind(sacc_num);
	end_ind = sacclist.end_ind(sacc_num);
	
	new_sacclist.as_ampl_horiz(sacc_num) = h_pos(end_ind) - h_pos(start_ind);
	new_sacclist.as_ampl_vert(sacc_num) = v_pos(end_ind) - v_pos(start_ind);
	
	[~, h_ind] = max(abs(h_vel(start_ind:end_ind)));
	new_sacclist.as_peak_vel_horiz(sacc_num) = h_vel(start_ind+h_ind-1);
	new_sacclist.as_peak_vel_horiz_ind(sacc_num) = h_ind + start_ind - 1;
	[~, v_ind] = max(abs(v_vel(start_ind:end_ind)));
	new_sacclist.as_peak_vel_vert(sacc_num) = v_vel(v_ind + start_ind - 1);
	new_sacclist.as_peak_vel_vert_ind(sacc_num) = v_ind + start_ind - 1;
end % each saccade in sacclist





