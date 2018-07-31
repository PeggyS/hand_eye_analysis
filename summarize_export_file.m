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
fprintf(fid, 'total time  = %g\n', time_in_file);
fprintf(fid, 'excluded time = %g\n', excluded_time_total);


% saccade summary
sacc_type_list = {'lh' 'lv' 'rh' 'rv'};
sacc_source_list = {'EDF_PARSER', 'findsaccs', 'engbert'};
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
	if iscell(tbl.blinks)
		
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
	keyboard
end % target_t is a column - smooth pursuit data

fclose(fid);






