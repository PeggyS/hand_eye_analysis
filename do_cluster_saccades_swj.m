function h = do_cluster_saccades_swj(h)

[fpath, fname, ext] = fileparts(h.bin_filename);

% input params for cluster detection
folder = fpath; % location to store files created by cluster detection
session = ['cluster_saccades_' fname]; % subfolder name for stored files
% matrix with cols = index (1:length), lh, lv, rh, rv (eyepos in deg)

samples = [(1:length(h.eye_data.rh.pos))' h.eye_data.lh.pos h.eye_data.lv.pos h.eye_data.rh.pos h.eye_data.rv.pos];

% blinks = binary vector indicating blink(1), (0) not
% filter to expand beyond the nan data
blinks = filtfilt(ones(100,1)',1,double(isnan(mean(samples')')));

% creates class for cluster detection of saccades
recording = ClusterDetection.EyeMovRecording.Create(folder, session, samples, blinks, h.eye_data.samp_freq);

% Runs the saccade detection
[saccades stats] = recording.FindSaccades();

% get the column names of saccades matrix
col_struct = ClusterDetection.SaccadeDetector.GetEnum;
col_names = fieldnames(col_struct);
% save saccades as a table so there are column names
sac_tbl = array2table(saccades, 'VariableNames', col_names);
save(fullfile(folder, session, 'saccade_table'), 'sac_tbl')

% save saccades in eye_data.(eye).saccades
eye_list = {'rh' 'rv' 'lh' 'lv'};

for ee = 1:length(eye_list)
	eye_str = eye_list{ee};
	
	sac_type_num = 1;
	if isfield(h.eye_data.(eye_str), 'saccades')
		sac_type_num = length(h.eye_data.(eye_str).saccades) +1; % (index of the next type of saccades to store)
	end
	
	h.eye_data.(eye_str).saccades(sac_type_num).sacclist.start_ind = saccades(:,1)';
	h.eye_data.(eye_str).saccades(sac_type_num).sacclist.end_ind = saccades(:,2)';

	h.eye_data.(eye_str).saccades(sac_type_num).sacclist.start = saccades(:,1)' / h.eye_data.samp_freq * 1000 + h.eye_data.start_times; % time in ms
	h.eye_data.(eye_str).saccades(sac_type_num).sacclist.end = saccades(:,2)' / h.eye_data.samp_freq * 1000 + h.eye_data.start_times;
%         sacclist.end = sac(:,2)' / samp_freq * 1000;
% 		sacclist.peak_vel = sac(:,3)'/60;	% converting from minutes to degrees
% 		sacclist.sacc_ampl = sac(:,4)'/60;
% 		sacclist.sacc_horiz_component = sac(:,6)'/60;
% 		sacclist.sacc_vert_component = sac(:,7)'/60;
% 		sacclist.peak_vel_horiz_component = sac(:,8)'/60;
% 		sacclist.peak_vel_vert_component = sac(:,9)'/60;
% 		
% 
% 		sacclist = compute_diff_vel_peaks(sacclist, h.eye_data.(h_str).pos, h.eye_data.(v_str).pos, samp_freq);
% 		sacclist = compute_drift(sacclist, h.eye_data.(h_str).pos, h.eye_data.(v_str).pos, samp_freq);
				
		h.eye_data.(eye_str).saccades(sac_type_num).paramtype = 'cluster';

end % save saccades to handles

% do figures


