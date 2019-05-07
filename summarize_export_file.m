function summarize_export_file(varargin)

if nargin
	fname = varargin{1};
else
	disp('choose the export file to summarize...')
	[fnSave, pnSave] = uigetfile({'*.txt'}, 'export .txt file ...');
	if isequal(fnSave,0) || isequal(pnSave,0)
		disp('no  file chosen ... ')
	return
	end
	fname = fullfile(pnSave, fnSave);
end

tbl = readtable(fname, 'delimiter', '\t');

% determine viewing eye from table column names
tmp = strfind(tbl.Properties.VariableNames, 'nve'); % cell array with cell of 1 if nve is in col name
tmp2 = find(~cellfun(@isempty, tmp)); % indices of tbl.Properties.VariableNames with 'nve'
first_var = tbl.Properties.VariableNames{tmp2(1)};
nveh = strrep(first_var, 'nve_', '');
nve = strrep(nveh, 'h', '');
if strcmp(nve, 'r')
	ve = 'l';
else
	ve = 'r';
end

time_in_file = tbl.t_eye(end) - tbl.t_eye(1);

% look for excluded data in tbl.annotation
excl_inds = [];
if iscell(tbl.annotation)
	excl_match_cell = regexp(tbl.annotation, '.*exclud.*');
	excl_inds = find(~cellfun(@isempty,excl_match_cell));
end
excluded_time_total = 0;
found_excl_beg = 0;

excluded_segments_count = 0;

for ex_cnt = 1:length(excl_inds)
	if strncmp(tbl.annotation(excl_inds(ex_cnt)), 'beg', 3)
		excluded_segments_count = excluded_segments_count + 1;
		found_excl_beg = 1;
		exclude_beg_time(excluded_segments_count) = tbl.t_eye(excl_inds(ex_cnt)); %#ok<AGROW>
	end
	if strncmp(tbl.annotation(excl_inds(ex_cnt)), 'end', 3)
		if ~found_excl_beg
			warning('found exclusion end without a beginning')
		else
			exclude_end_time(excluded_segments_count) = tbl.t_eye(excl_inds(ex_cnt)); %#ok<AGROW>
			excluded_time_total = excluded_time_total + (exclude_end_time(excluded_segments_count) - ...
				exclude_beg_time(excluded_segments_count));
			found_excl_beg = 0;
		end
	end
end

out_fname = strrep(fname, '.txt', '_summary.txt');

fid = fopen(out_fname, 'w');
if strcmp(ve, 'r')
	fprintf(fid, 'viewing eye = right\n');
else
	fprintf(fid, 'viewing eye = left\n');
end
fprintf(fid, 'total time  = %g\n', time_in_file);
fprintf(fid, 'excluded time = %g\n', excluded_time_total);


% saccade summary
sacc_type_list = {'lh' 'lv' 'rh' 'rv'};

tmp = regexpi(tbl.Properties.VariableNames, '(edf_parser)|(engbert)|(findsaccs)', 'match');
tmp(cellfun(@isempty, tmp)) = []; % remove empty cells
tmp2 = [tmp{:}];
sacc_source_list = unique(tmp2); %% {'EDF_PARSER', 'findsaccs', 'engbert'};

for eye_cnt = 1:length(sacc_type_list)
	for source_cnt = 1:length(sacc_source_list)
		sacc_fname = strrep(fname, '.txt', ['_', sacc_source_list{source_cnt} '_' sacc_type_list{eye_cnt} '.txt']);
		if exist(sacc_fname, 'file')
% 			keyboard
			sacc_tbl = readtable(sacc_fname);
			% remove exluded time segments
			for ex_seg_cnt = 1:excluded_segments_count
% 				keyboard
				sacc_tbl(sacc_tbl.startTime >= exclude_beg_time(ex_seg_cnt) & ...
						 sacc_tbl.startTime <= exclude_end_time(ex_seg_cnt), :) = [];
			end % excluded segments
			
			% number of < 1° saccades
			small_sacc_inds = find(sacc_tbl.Ampl < 1);
			fprintf(fid, '%s %s number of < 1 deg saccades = %d\n', sacc_source_list{source_cnt}, ...
				sacc_type_list{eye_cnt}, length(small_sacc_inds));
			
			% number of >= 1° saccades
			large_sacc_inds = find(sacc_tbl.Ampl >= 1);
			fprintf(fid, '%s %s number of >= 1 deg saccades = %d\n', sacc_source_list{source_cnt}, ...
				sacc_type_list{eye_cnt}, length(large_sacc_inds));
			
			% examine saccades for the other eye
			switch sacc_type_list{eye_cnt}(1)
				case 'r'
					other_eye = strrep(sacc_type_list{eye_cnt}, 'r', 'l');
				case 'l'
					other_eye = strrep(sacc_type_list{eye_cnt}, 'l', 'r');
				otherwise
					error('unknown sacc_type: %s', sacc_type_list{eye_cnt})
			end
			other_sacc_fname = strrep(fname, '.txt', ['_', sacc_source_list{source_cnt} '_' other_eye '.txt']);
			if exist(other_sacc_fname, 'file')
				other_sacc_tbl = readtable(other_sacc_fname);
				% remove exluded time segments
				for ex_seg_cnt = 1:excluded_segments_count
				other_sacc_tbl(other_sacc_tbl.startTime >= exclude_beg_time(ex_seg_cnt) & ...
						 other_sacc_tbl.startTime <= exclude_end_time(ex_seg_cnt), :) = [];
				end % excluded segments
% 				keyboard
				% look for nonoverlapping saccades of the other eye
				nonoverlap_inds = find_nonoverlapping_saccades(sacc_tbl, other_sacc_tbl);
				% if no overlapping saccade, get the other eye's info during the saccade

				if ~isempty(nonoverlap_inds)
					sacc_start = sacc_tbl.startTime(nonoverlap_inds);
					sacc_end =  sacc_tbl.endTime(nonoverlap_inds);
					other_eye_info_tbl = get_other_eye_info(tbl, sacc_start, sacc_end, other_eye);
					
					new_sacc_tbl = outerjoin(sacc_tbl, other_eye_info_tbl, 'MergeKeys', true);
					new_filename = strrep(sacc_fname, '.txt', '_plus_other_eye_non_sacc_info.txt');
					writetable(new_sacc_tbl, new_filename, 'delimiter', '\t');
				else
					disp('no monocular saccades detected')
 				end % non overlapping saccade
			end
		end %sacc_source & type file exists
	end % sacc_source
end % sacc_type

% if it's a smooth pursuit file, there will be a column with target_t
if any(strcmp(tbl.Properties.VariableNames, 'target_t'))
	
	sm_out_tbl = tbl;
	
	blink_time_total = 0;
	blink_segments_count = 0;

	% look for blinks in sm_out_tbl.blinks and remove them
	if any(strcmp(tbl.Properties.VariableNames, 'blinks'))
		
		blink_match_cell = regexp(sm_out_tbl.blinks, 'blink.*_begin');
		blink_beg_ind_list = find(~cellfun(@isempty,blink_match_cell));

		while ~isempty(blink_beg_ind_list)
			blink_beg_ind = blink_beg_ind_list(1);
	 		% corresponding blink end
			end_str = strrep(sm_out_tbl.blinks{blink_beg_ind}, 'begin', 'end');
			tmp = strfind(sm_out_tbl.blinks, end_str);
			end_ind = find(~cellfun(@isempty,tmp));
			
			if isempty(end_ind)
				warning('did not find blink end corresponding to %s', sm_out_tbl.blinks{blink_beg_ind})
			else
				blink_segments_count = blink_segments_count + 1;
				blink_beg_time = sm_out_tbl.t_eye(blink_beg_ind);
				blink_end_time = sm_out_tbl.t_eye(end_ind);
				blink_time_total = blink_time_total + (blink_end_time - blink_beg_time);
				
				% remove the data from the table
				sm_out_tbl(blink_beg_ind:end_ind,:) = [];
				% search for more blinks
				blink_match_cell = regexp(sm_out_tbl.blinks, 'blink.*_begin');
				blink_beg_ind_list = find(~cellfun(@isempty,blink_match_cell));
					
			end
		end % while there are still blinks in the table
	end % there is a blinks column
	fprintf(fid, 'smooth pursuit: removed %d blinks, total time duration = %g\n', ...
		blink_segments_count, blink_time_total);
	
	% remove saccades
	% what type of saccades are in the table?
	tmp = regexpi(sm_out_tbl.Properties.VariableNames, '(edf_parser)|(engbert)|(findsaccs)', 'match');
	tmp(cellfun(@isempty, tmp)) = []; % remove empty cells
	tmp2 = [tmp{:}];
	
	sac_types = strrep(unique(tmp2), 'EDF_PARSER', 'eyelink');
	% ask what type of saccades to remove from the data
	disp('There are more than 1 type of saccades in the export file. Select which type to summarize.')
	if numel(sac_types) > 1
		[sel, ok] = listdlg('ListString', sac_types, 'SelectionMode', 'single', 'Name', 'Saccade Type');
	else
		sel = 1; ok = 1;
	end
	if ok
		s_type = strrep(sac_types{sel}, 'eyelink', 'EDF_PARSER');
		sacc_mask = zeros(height(sm_out_tbl), 1); % 1 = saccade data, 0 = non saccade data
		
		% discontinuities in time
		t_diff = diff(sm_out_tbl.t_eye);
		t_diff_min = min(unique(t_diff));
		
		% find if there are columns for rh, lh, rv, lv
		tmp = regexpi(sm_out_tbl.Properties.VariableNames, [s_type '_((r)|(l))((h)|(v))_saccades$'], 'match');
		tmp(cellfun(@isempty, tmp)) = []; % remove empty cells
		sacc_cols = [tmp{:}];
		
		for c_cnt = 1:length(sacc_cols) % each table column of saccades
			% find saccade starts
			tmp = regexp(sm_out_tbl.(sacc_cols{c_cnt}), '_\d+_start$', 'match');
			tmp(cellfun(@isempty, tmp)) = []; % remove empty cells
			sacc_starts = [tmp{:}];
			
			% find corresponding sacc ends

			% if a saccade end for 2 different saccades was at the same
			% time, the 1st saccade end is written over in the export file

			for ss_cnt = 1:length(sacc_starts)
				idx_start = find(contains(sm_out_tbl.(sacc_cols{c_cnt}), sacc_starts{ss_cnt}));
				idx_end = find(contains(sm_out_tbl.(sacc_cols{c_cnt}), strrep(sacc_starts{ss_cnt}, 'start', 'end')));
				if isempty(idx_end)
					% missing saccade end - probably because it was rmoved
					% with a blink or overwritten by another saccade ending
					% at the same time
					if ss_cnt + 1 >= length(sacc_starts) % there are no more sacc starts, exclude everything to the end
						idx_end = height(sm_out_tbl);
					else
						% look for the index of the next discontinuity in time
						% or the start of the next saccade, whichever is sooner
						% the next saccade start
						idx_next_start = find(contains(sm_out_tbl.(sacc_cols{c_cnt}), sacc_starts{ss_cnt+1}));
						% the end of the next discontinuity in time
						idx_discont = find(t_diff(idx_start:end)>t_diff_min*1.5, 1) + idx_start;
						idx_end = min([idx_next_start idx_discont]);
					end
				end	%for each saccade start
                
				% make the saccade mask between indices = 1
				sacc_mask(idx_start:idx_end) = 1;
			end
		end
		
		% remove the saccades from the sm_out_tbl
		sm_out_tbl(logical(sacc_mask),:) = [];
		
		% summarize the saccades from sacc_mask
		start_ones = strfind([0 sacc_mask'],[0 1]);
		% start_zeros = strfind([1 sacc_mask'],[1 0])
		stop_ones = strfind([sacc_mask' 0],[1 0]);
		% stop_zeros = strfind([sacc_mask' 1],[0 1])

		% Get lengths of islands of ones and zeros using those start-stop indices 
% 		length_ones = stop_ones - start_ones + 1;
		% length_zeros = stop_zeros - start_zeros + 1
		
		fprintf(fid, 'smooth pursuit: removed %d %s saccades, total number of samples = %g, time =  %g\n', ...
			length(start_ones), s_type, sum(sacc_mask), sum(sacc_mask)*t_diff_min);
	else
		disp('Not removing saccades from smooth pursuit data.')
	end
	
	% is there head threshold column? HEAD_below_threshold = 1 -> keep data,
	% head is not moving; HEAD_below_threshold = 0 -> remove this data,
	% head is moving too much
	if any(strcmp(tbl.Properties.VariableNames, 'HEAD_below_threshold')) 
		% remove 0
		msk = ~sm_out_tbl.HEAD_below_threshold; % msk = 1 -> points to remove
		sm_out_tbl(logical(msk),:) = [];
		% summarize what was removed
		start_ones = strfind([0 msk'],[0 1]);
		stop_ones = strfind([msk' 0],[1 0]);
		fprintf(fid, 'smooth pursuit: removed %d segments with head motion above threshold, total number of samples = %g\n', ...
			length(start_ones), sum(msk)*min(unique(diff(sm_out_tbl.t_eye))));
	end
	
	% add column to smooth p output table
	eye_vel_list = {'rh_vel', 'lh_vel', 'rv_vel', 'lv_vel'};
	for e_cnt = 1:length(eye_vel_list)
		if any(strcmp(sm_out_tbl.Properties.VariableNames, eye_vel_list{e_cnt}))
			varname = strrep(eye_vel_list{e_cnt}, '_vel', '_gain');
			switch eye_vel_list{e_cnt}
				case {'rh_vel', 'lh_vel'}
					targ_varname = 'target_xvel_deg_s';
				case {'rv_vel', 'lv_vel'}
					targ_varname = 'target_yvel_deg_s';
			end
			sm_out_tbl.(varname) =  sm_out_tbl.(eye_vel_list{e_cnt}) ./ sm_out_tbl.(targ_varname);
		end
	end
	% save the smooth pursuit data without blinks, saccades, & head
	% movement to a new file

	writetable(sm_out_tbl, strrep(fname, '.txt', '_smooth_pursuit.txt'), 'delimiter', '\t')
end % target_t is a column - smooth pursuit data

fclose(fid); % summary file






