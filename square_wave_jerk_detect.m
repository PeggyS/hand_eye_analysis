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
					eye_data.(eye).saccades(source_num).sacclist.endpos = eye_data.(eye).pos(endIndex);
					if length(eye_data.(eye_other_direction).saccades) >= source_num % check that other eye dir has saccades of this type - FIXME - this just checks the length of the saccades struc - what if there are other saccade types without both h & v and the source_num for the h & v saccades of this type don't match??
						if ~isfield(eye_data.(eye_other_direction).saccades(source_num).sacclist, 'endpos')
							eye_data.(eye_other_direction).saccades(source_num).sacclist.endpos = eye_data.(eye).pos(endIndex);
						end
					else
						error('no saccades for %s of type %s', eye_other_direction, eye_data.(eye).saccades(source_num).paramtype)
					end
				end
				if ~isfield(eye_data.(eye).saccades(source_num).sacclist, 'startpos') 
					% startpos is not a field, calculate it
					eye_data.(eye).saccades(source_num).sacclist.startpos = eye_data.(eye).pos(startIndex);
					if length(eye_data.(eye_other_direction).saccades) >= source_num % check that other eye dir has saccades of this type - FIXME - this just checks the length of the saccades struc - what if there are other saccade types without both h & v and the source_num for the h & v saccades of this type don't match??
						if ~isfield(eye_data.(eye_other_direction).saccades(source_num).sacclist, 'startpos')
							eye_data.(eye_other_direction).saccades(source_num).sacclist.startpos = eye_data.(eye).pos(startIndex);
						end
					else
						error('no saccades for %s of type %s', eye_other_direction, eye_data.(eye).saccades(source_num).paramtype)
					end
				end
				
				
				% direction = angle betw 0 & 360, pure vertical = 0, 180,
				% horizontal = 90, 270
				if strcmp(eye_data.(eye).saccades(source_num).paramtype, 'findsaccs')
					amplitude = abs(eye_data.(eye).saccades(source_num).sacclist.endpos ...
						- eye_data.(eye).saccades(source_num).sacclist.startpos);
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
				else % for eyelink & engbert saccades use h & v eyes together to determine amplitude & direction
					% if engbert saccades are only in h but not v, then
					% this code will throw an error (index out of bounds) - FIXME
					
					if strcmp(eye, 'h')
						dx = eye_data.(eye).saccades(source_num).sacclist.endpos ...
							- eye_data.(eye).saccades(source_num).sacclist.startpos;
						dy = eye_data.(eye_other_direction).saccades(source_num).sacclist.endpos ...
							- eye_data.(eye_other_direction).saccades(source_num).sacclist.startpos;
					else
						dy = eye_data.(eye).saccades(source_num).sacclist.endpos ...
							- eye_data.(eye).saccades(source_num).sacclist.startpos;
						dx = eye_data.(eye_other_direction).saccades(source_num).sacclist.endpos ...
							- eye_data.(eye_other_direction).saccades(source_num).sacclist.startpos;
					end
					amplitude = sqrt(dx.^2 + dy.^2);
					directions	= atan2( dx, dy );
					direction = mod( (directions * (180 / pi)) + 360, 360);
					
				end
				blinks = filtfilt(ones(1,100), 1, double(isnan(eye_data.(eye).pos))); % extend blink (non-analyzed) data beyond nans - per script supplied by Fatema
				[swj1, swj2] = SWJDetection.swjs(  startIndex, endIndex, amplitude, direction, ...
					isnan(eye_data.(eye).pos), eye_data.samp_freq );
				new_eye_data.(eye).saccades(source_num).sacclist.swj(1,:) = nan(1,length(new_eye_data.(eye).saccades(source_num).sacclist.start));
				new_eye_data.(eye).saccades(source_num).sacclist.swj(1,swj1) = 1:length(swj1);
				new_eye_data.(eye).saccades(source_num).sacclist.swj(1,swj2) = 1:length(swj2);
			end
		end
	end %source_num
end % eye