function new_eye_data = square_wave_jerk_detect(eye_data)
new_eye_data = eye_data;

eye_list = {'rh', 'lh', 'rv', 'lv'};

for eye_cnt = 1:length(eye_list)
	eye = eye_list{eye_cnt};
	% the other direction h/v of the eye
	if contains(eye, 'h')
		eye_other_direction = strrep(eye, 'h', 'v');
	else
		eye_other_direction = strrep(eye, 'v', 'h');
	end
	
	for source_num = 1:length(eye_data.(eye).saccades)
		if ~isfield(eye_data.(eye).saccades(source_num).sacclist, 'swj')
			if isfield(eye_data.(eye).saccades(source_num).sacclist, 'start')
				startIndex = round((eye_data.(eye).saccades(source_num).sacclist.start - eye_data.start_times) / 1000 * eye_data.samp_freq);
				endIndex = round((eye_data.(eye).saccades(source_num).sacclist.end - eye_data.start_times) / 1000 * eye_data.samp_freq);
				if ~isfield(eye_data.(eye).saccades(source_num).sacclist, 'endpos') 
					% endpos is not a field, calculate it
				end
				if ~isfield(eye_data.(eye).saccades(source_num).sacclist, 'startpos') 
					% startpos is not a field, calculate it
				end
				amplitude = abs(eye_data.(eye).saccades(source_num).sacclist.endpos ...
					- eye_data.(eye).saccades.sacclist(source_num).startpos);
				% direction = angle betw 0 & 360, pure vertical = 0, 180,
				% horizontal = 90, 270
				if strcmp(eye_data.(eye).saccades.paramtype, 'findsaccs')
					if contains(eye, 'h')
						direction = sign(eye_data.(eye).saccades(source_num).sacclist.endpos ...
							- eye_data.(eye).saccades(source_num).sacclist.startpos);
						direction(direction==1) = 90; % pos horiz = 90
						direction(direction==-1) = 270; % neg horiz = 270
					else
						direction = sign(eye_data.(eye).saccades(source_num).sacclist.endpos ...
							- eye_data.(eye).saccades(source_num).sacclist.startpos);
						direction(direction==1) = 0; % pos vert = 0
						direction(direction==-1) = 180; % neg vert = 180
					end
				else % for eyelink & engbert saccades use h & v eyes together to determine direction
					if strcmp(eye, 'h')
						dx = eye_data.(eye).saccades(source_num).sacclist.endpos ...
							- eye_data.(eye).saccades.sacclist.startpos;
						dy = eye_data.(eye_other_direction).saccades(source_num).sacclist.endpos ...
							- eye_data.(eye_other_direction).saccades.sacclist.startpos;
					else
						dy = eye_data.(eye).saccades(source_num).sacclist.endpos ...
							- eye_data.(eye).saccades.sacclist.startpos;
						dx = eye_data.(eye_other_direction).saccades(source_num).sacclist.endpos ...
							- eye_data.(eye_other_direction).saccades.sacclist.startpos;
					end
					directions	= atan2( dx, dy );
					direction = mod( (directions * (180 / pi)) + 360, 360);
				end
				
				[swj1, swj2] = SWJDetection.swjs(  startIndex, endIndex, amplitude, direction, ...
					isnan(eye_data.(eye).pos), eye_data.samp_freq );
				new_eye_data.(eye).saccades(source_num).sacclist.swj(1,:) = nan(1,length(new_eye_data.(eye).saccades(source_num).sacclist.start));
				new_eye_data.(eye).saccades(source_num).sacclist.swj(1,swj1) = 1:length(swj1);
				new_eye_data.(eye).saccades(source_num).sacclist.swj(1,swj2) = 1:length(swj2);
			end
		end
	end %source_num
end % eye