function new_eye_data = enable_all_saccades(eye_data)
new_eye_data = eye_data;

eye_list = {'rh', 'lh', 'rv', 'lv'};
for eye_cnt = 1:length(eye_list)
	eye = eye_list{eye_cnt};
	for source_num = 1:length(eye_data.(eye).saccades)
		if ~isfield(eye_data.(eye).saccades(source_num).sacclist, 'enabled')
			new_eye_data.(eye).saccades(source_num).sacclist.enabled = ...
				ones(size(eye_data.(eye).saccades(source_num).sacclist.start));
		end
	end %source_num
end % eye