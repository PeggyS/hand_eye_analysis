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

% save saccades in eye_data.(eye).saccades

% do figures
