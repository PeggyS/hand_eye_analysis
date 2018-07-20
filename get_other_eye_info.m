function other_eye_info_tbl = get_other_eye_info(tbl, sacc_start, sacc_end, other_eye)

samp_freq = 1/mode(diff(tbl.t_eye));

h_other_eye = strrep(other_eye, 'v', 'h');
h_pos = tbl.(h_other_eye);
v_other_eye = strrep(other_eye, 'h', 'v');
v_pos = tbl.(v_other_eye);

% norm pos
norm_pos = sqrt(h_pos.^2 + v_pos.^2);

% velocity
h_vel = diff(h_pos)*samp_freq;
v_vel = diff(v_pos)*samp_freq;

% filter the velocity
h_vel_filt = sgolayfilt(h_vel, 3, 11);
v_vel_filt = sgolayfilt(v_vel, 3, 11);
norm_vel = sqrt(h_vel_filt.^2 + v_vel_filt.^2);

other_eye_info.startTime = nan(size(sacc_start));
other_eye_info.endTime = nan(size(sacc_start));
other_eye_info.DriftMeanTime = nan(size(sacc_start));
other_eye_info.asAmplH = nan(size(sacc_start));
other_eye_info.asAmplV = nan(size(sacc_start));
other_eye_info.asPeakVelH = nan(size(sacc_start));
other_eye_info.asPeakVelHtime = nan(size(sacc_start));
other_eye_info.asPeakVelV = nan(size(sacc_start));
other_eye_info.asPeakVelVtime = nan(size(sacc_start));
other_eye_info.DriftMedianVelHor = nan(size(sacc_start));
other_eye_info.DriftMeanVelHor = nan(size(sacc_start));
other_eye_info.DriftVarVelHor = nan(size(sacc_start));
other_eye_info.DriftStdVelHor = nan(size(sacc_start));
other_eye_info.DriftMedianVelVert = nan(size(sacc_start));
other_eye_info.DriftMeanVelVert = nan(size(sacc_start));
other_eye_info.DriftVarVelVert = nan(size(sacc_start));
other_eye_info.DriftStdVelVert = nan(size(sacc_start));
other_eye_info.DriftMedianVel = nan(size(sacc_start));
other_eye_info.DriftMeanVel = nan(size(sacc_start));
other_eye_info.DriftVarVel = nan(size(sacc_start));
other_eye_info.DriftStdVel = nan(size(sacc_start));
other_eye_info.DriftMedianPos = nan(size(sacc_start));
other_eye_info.DriftMeanPos = nan(size(sacc_start));
other_eye_info.DriftVarPos = nan(size(sacc_start));
other_eye_info.DriftStdPos = nan(size(sacc_start));


for sacc_num = 1:length(sacc_start)
	other_eye_info.startTime (sacc_num)= sacc_start(sacc_num);
	other_eye_info.endTime(sacc_num) = sacc_end(sacc_num);
	other_eye_info.DriftMeanTime(sacc_num) = mean([sacc_start(sacc_num), sacc_end(sacc_num)]);
	start_ind = find(tbl.t_eye >= sacc_start(sacc_num), 1);
	end_ind = find(tbl.t_eye >= sacc_end(sacc_num), 1);
	
	if ~any(isnan(h_pos(start_ind:end_ind)))
		other_eye_info.asAmplH(sacc_num) = h_pos(end_ind) - h_pos(start_ind);
	end
	if ~any(isnan(v_pos(start_ind:end_ind)))
		other_eye_info.asAmplV(sacc_num) = v_pos(end_ind) - v_pos(start_ind);
	end

	if ~any(isnan(h_vel_filt(start_ind:end_ind)))
		[other_eye_info.asPeakVelH(sacc_num), ind] = max(h_vel_filt(start_ind:end_ind));
		other_eye_info.asPeakVelHtime(sacc_num) = tbl.t_eye(start_ind+ind-1);
		other_eye_info.DriftMedianVelHor(sacc_num) = median(h_vel_filt(start_ind:end_ind));
		other_eye_info.DriftMeanVelHor(sacc_num) = mean(h_vel_filt(start_ind:end_ind));
		other_eye_info.DriftVarVelHor(sacc_num) = var(h_vel_filt(start_ind:end_ind));
		other_eye_info.DriftStdVelHor(sacc_num) = std(h_vel_filt(start_ind:end_ind));
	end
	if ~any(isnan(v_vel_filt(start_ind:end_ind)))
		[other_eye_info.asPeakVelV(sacc_num), ind] = max(v_vel_filt(start_ind:end_ind));
		other_eye_info.asPeakVelVtime(sacc_num) = tbl.t_eye(start_ind+ind-1);
		other_eye_info.DriftMedianVelVert(sacc_num) = median(v_vel_filt(start_ind:end_ind));
		other_eye_info.DriftMeanVelVert(sacc_num) = mean(v_vel_filt(start_ind:end_ind));
		other_eye_info.DriftVarVelVert(sacc_num) = var(v_vel_filt(start_ind:end_ind));
		other_eye_info.DriftStdVelVert(sacc_num) = std(v_vel_filt(start_ind:end_ind));
	end
	if ~any(isnan(norm_vel(start_ind:end_ind)))
		other_eye_info.DriftMedianVel(sacc_num) = median(norm_vel(start_ind:end_ind));
		other_eye_info.DriftMeanVel(sacc_num) = mean(norm_vel(start_ind:end_ind));
		other_eye_info.DriftVarVel(sacc_num) = var(norm_vel(start_ind:end_ind));
		other_eye_info.DriftStdVel(sacc_num) = std(norm_vel(start_ind:end_ind));
	end
	if ~any(isnan(norm_pos(start_ind:end_ind)))
		other_eye_info.DriftMedianPos(sacc_num) = median(norm_pos(start_ind:end_ind));
		other_eye_info.DriftMeanPos(sacc_num) = mean(norm_pos(start_ind:end_ind));
		other_eye_info.DriftVarPos(sacc_num) = var(norm_pos(start_ind:end_ind));
		other_eye_info.DriftStdPos(sacc_num) = std(norm_pos(start_ind:end_ind));
	end
end % each saccade

other_eye_info_tbl = struct2table(other_eye_info);
other_eye_info_tbl.Properties.VariableNames(2:end) = strcat(other_eye_info_tbl.Properties.VariableNames(2:end), upper(other_eye(1)));
return


	
	