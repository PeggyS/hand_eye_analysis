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
	nve = 'r';
else
	ve = 'r';
	nve = 'l';
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

% head angle at begin & end
head_ang_col = find(strcmpi(tbl.Properties.VariableNames, 'HEAD_angle'));
if ~isempty(head_ang_col)
	fprintf(fid, 'begin head angle = %g\n', table2array(tbl(1,head_ang_col)));
	fprintf(fid, 'end head angle = %g\n', table2array(tbl(end,head_ang_col)));
	fprintf(fid, 'head angle movement = %g\n', table2array(tbl(end,head_ang_col))-table2array(tbl(1,head_ang_col)));
end

% right or left hand movements
tmp = regexpi(tbl.Properties.VariableNames, '_moves', 'match');
move_col = find(~cellfun(@isempty, tmp));
for mm = 1:length(move_col)
	col = move_col(mm);
	move_list = table2cell(tbl(:,col));
	rows = find(~cellfun(@isempty, move_list));
	
	for rr = 1:length(rows)
		tbl_row = rows(rr);
		val = table2cell(tbl(tbl_row,col));
		fprintf(fid, 't = %g; %s - %s\n', table2array(tbl(tbl_row,1)), tbl.Properties.VariableNames{col}, val{1});
	end
end


% saccade summary
sacc_type_list = {'lh' 'lv' 'rh' 'rv'};

tmp = regexpi(tbl.Properties.VariableNames, '(edf_parser)|(engbert)|(findsaccs)', 'match');
tmp(cellfun(@isempty, tmp)) = []; % remove empty cells
tmp2 = [tmp{:}];
sacc_source_list = unique(tmp2); %% {'EDF_PARSER', 'findsaccs', 'engbert'};

for eye_cnt = 1:length(sacc_type_list)
	for source_cnt = 1:length(sacc_source_list)
		sacc_fname = strrep(fname, '.txt', ['_', sacc_source_list{source_cnt} '_' sacc_type_list{eye_cnt} '_ve.txt']);
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
			large_sacc_inds = find(sacc_tbl.swj >= 1);
			fprintf(fid, '%s %s number of >= 1 deg saccades = %d\n', sacc_source_list{source_cnt}, ...
				sacc_type_list{eye_cnt}, length(large_sacc_inds));
			
			% number of square wave jerks
			swj_uniques = unique(sacc_tbl.swj);
			num_swj = sum(~isnan(swj_uniques));
			fprintf(fid, '%s %s number of swjs = %d\n', sacc_source_list{source_cnt}, ...
				sacc_type_list{eye_cnt}, num_swj);
			
			% examine saccades for the other eye
% 			switch sacc_type_list{eye_cnt}(1)
% 				case 'r'
% 					other_eye = strrep(sacc_type_list{eye_cnt}, 'r', 'l');
% 				case 'l'
% 					other_eye = strrep(sacc_type_list{eye_cnt}, 'l', 'r');
% 				otherwise
% 					error('unknown sacc_type: %s', sacc_type_list{eye_cnt})
% 			end
% 			other_sacc_fname = strrep(fname, '.txt', ['_', sacc_source_list{source_cnt} '_' other_eye '.txt']);
			other_sacc_fname = strrep(sacc_fname, [ve 'h_ve'], [nve 'h_nve']);
			if exist(other_sacc_fname, 'file')
				other_sacc_tbl = readtable(other_sacc_fname);
				% remove exluded time segments
				for ex_seg_cnt = 1:excluded_segments_count
					other_sacc_tbl(other_sacc_tbl.startTime >= exclude_beg_time(ex_seg_cnt) & ...
						 other_sacc_tbl.startTime <= exclude_end_time(ex_seg_cnt), :) = [];
				end % excluded segments

				% merge ve saccade info with non ve saccade info - save in a
				% single file
				comb_sacc_tbl = sacc_tbl;
				comb_sacc_tbl.Properties.VariableNames = strcat(comb_sacc_tbl.Properties.VariableNames, ['_' ve '_ve']);

				empty_tbl = array2table(nan(height(comb_sacc_tbl), width(other_sacc_tbl)), ...
					'VariableNames', strcat(other_sacc_tbl.Properties.VariableNames, ['_' nve '_nve']));
				% change VariableNames with 'word' to cell instead of NaN
				tmp = regexp(empty_tbl.Properties.VariableNames, '.*word.*', 'match');
				msk = ~cellfun(@isempty, tmp);
				word_var_inds = find(msk);
				match_cells = tmp(msk);
				for m_cnt = 1:length(match_cells)
					var_name = match_cells{m_cnt}{1};
					empty_tbl.(var_name) = cell(height(comb_sacc_tbl),1);
				end
				startTime_nve_ind = width(sacc_tbl) + 1;
				
				comb_sacc_tbl = horzcat(comb_sacc_tbl, empty_tbl); %#ok<AGROW>
				nve_inds = width(sacc_tbl) + (1 : width(other_sacc_tbl));
				comb_sacc_tbl.ve_nve_overlap = ones(height(comb_sacc_tbl),1); % 0 or 1 overlaping ve & nve saccades
				comb_sacc_tbl.nve_non_sacc_startpos_h = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_endpos_h = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_variancepos_h = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_medianpos_h = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_meanpos_h = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_variancevel_h = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_medianvel_h = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_meanvel_h = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_startpos_v = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_endpos_v = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_variancepos_v = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_medianpos_v = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_meanpos_v = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_variancevel_v = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_medianvel_v = nan(height(comb_sacc_tbl),1);
				comb_sacc_tbl.nve_non_sacc_meanvel_v = nan(height(comb_sacc_tbl),1);
				for row = 1:height(sacc_tbl)
					overlap_ind = find((other_sacc_tbl.startTime >= sacc_tbl.startTime(row) & other_sacc_tbl.endTime <= sacc_tbl.endTime(row)) | ...
						(other_sacc_tbl.endTime > sacc_tbl.startTime(row) & other_sacc_tbl.endTime <= sacc_tbl.endTime(row)) | ...
						(other_sacc_tbl.startTime >= sacc_tbl.startTime(row) & other_sacc_tbl.startTime < sacc_tbl.endTime(row)) | ...
						(other_sacc_tbl.startTime <= sacc_tbl.startTime(row) & other_sacc_tbl.endTime >= sacc_tbl.endTime(row)));
					if length(overlap_ind) > 1
						msg_str = sprintf('found more than 1 overlapping saccade at %s_ve saccade start time = %g\n %s_nve saccade start times t =', ...
							ve, sacc_tbl.endTime(row), nve);
						for ii = 1:length(overlap_ind)
							msg_str = [msg_str  '  ' num2str(other_sacc_tbl.startTime(overlap_ind(ii))) ]; %#ok<AGROW>
						end
						msg_str = sprintf([msg_str '\n only the 1st overlapping saccade will be used']); %#ok<AGROW>
						warning(msg_str) %#ok<SPWRN>
						overlap_ind = overlap_ind(1);
					end
					if ~isempty(overlap_ind)
						comb_sacc_tbl(row, nve_inds) = other_sacc_tbl(overlap_ind,:);
					else 
						% other eye info when there is no overlapping saccade
						comb_sacc_tbl.ve_nve_overlap(row) = 0;
						non_sacc_data = tbl(tbl.t_eye >= sacc_tbl.startTime(row) & tbl.t_eye <= sacc_tbl.endTime(row), ...
							{['nve_' nve 'h'], ['nve_' nve 'v'], ['nve_' nve 'h_vel'], ['nve_' nve 'v_vel']});
						comb_sacc_tbl.nve_non_sacc_startpos_h(row) = table2array(non_sacc_data(1,1));
						comb_sacc_tbl.nve_non_sacc_endpos_h(row) = table2array(non_sacc_data(height(non_sacc_data),1));
						comb_sacc_tbl.nve_non_sacc_variancepos_h(row) = var(table2array(non_sacc_data(:,1)));
						comb_sacc_tbl.nve_non_sacc_medianpos_h(row) = median(table2array(non_sacc_data(:,1)));
						comb_sacc_tbl.nve_non_sacc_meanpos_h(row) = mean(table2array(non_sacc_data(:,1)));
						comb_sacc_tbl.nve_non_sacc_variancevel_h(row) = var(table2array(non_sacc_data(:,3)));
						comb_sacc_tbl.nve_non_sacc_medianvel_h(row) = median(table2array(non_sacc_data(:,3)));
						comb_sacc_tbl.nve_non_sacc_meanvel_h(row) = mean(table2array(non_sacc_data(:,3)));
						
						comb_sacc_tbl.nve_non_sacc_startpos_v(row) = table2array(non_sacc_data(1,2));
						comb_sacc_tbl.nve_non_sacc_endpos_v(row) = table2array(non_sacc_data(height(non_sacc_data),2));
						comb_sacc_tbl.nve_non_sacc_variancepos_v(row) = var(table2array(non_sacc_data(:,2)));
						comb_sacc_tbl.nve_non_sacc_medianpos_v(row) = median(table2array(non_sacc_data(:,2)));
						comb_sacc_tbl.nve_non_sacc_meanpos_v(row) = mean(table2array(non_sacc_data(:,2)));
						comb_sacc_tbl.nve_non_sacc_variancevel_v(row) = var(table2array(non_sacc_data(:,4)));
						comb_sacc_tbl.nve_non_sacc_medianvel_v(row) = median(table2array(non_sacc_data(:,4)));
						comb_sacc_tbl.nve_non_sacc_meanvel_v(row) = mean(table2array(non_sacc_data(:,4)));
					end
				end
				% look for nonoverlapping saccades of the other eye
				other_eye_nonoverlap_inds = find_other_eye_nonoverlapping_saccades(sacc_tbl, other_sacc_tbl);
				if ~isempty(other_eye_nonoverlap_inds)
					% add these other eye saccades to the comb_sacc_tbl
					% with more columns for ve info during nve saccade
					comb_sacc_tbl.ve_non_sacc_startpos_h = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_endpos_h = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_variancepos_h = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_medianpos_h = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_meanpos_h = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_variancevel_h = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_medianvel_h = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_meanvel_h = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_startpos_v = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_endpos_v = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_variancepos_v = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_medianpos_v = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_meanpos_v = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_variancevel_v = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_medianvel_v = nan(height(comb_sacc_tbl),1);
					comb_sacc_tbl.ve_non_sacc_meanvel_v = nan(height(comb_sacc_tbl),1);
					
					tmp = regexp(comb_sacc_tbl.Properties.VariableNames, '.*word.*', 'match');
					msk = ~cellfun(@isempty, tmp);
					word_var_inds = find(msk);
				
					for scnt = 1:length(other_eye_nonoverlap_inds)
						other_ind = other_eye_nonoverlap_inds(scnt);
						msk = comb_sacc_tbl{:,startTime_nve_ind} < other_sacc_tbl{other_ind,1};
						ve_nan_row = array2table(nan(1,startTime_nve_ind-1), 'VariableNames', comb_sacc_tbl.Properties.VariableNames(1:startTime_nve_ind-1));
						ve_nve_ol_row = array2table(zeros(1,1), 'VariableNames', {'ve_nve_overlap'});
						non_sac_row = array2table(nan(1,32), 'VariableNames', comb_sacc_tbl.Properties.VariableNames(end-31:end));
						new_row = [ve_nan_row other_sacc_tbl(other_ind,:)  ve_nve_ol_row non_sac_row];
						new_row.Properties.VariableNames =  comb_sacc_tbl.Properties.VariableNames;
						new_row_num = sum(msk)+1;

						tmp1 = [comb_sacc_tbl(msk,:);  new_row; comb_sacc_tbl(~msk,:)];
						comb_sacc_tbl = tmp1;	
						
						non_sacc_data = tbl(tbl.t_eye >= other_sacc_tbl.startTime(other_ind) & tbl.t_eye <= other_sacc_tbl.endTime(other_ind), ...
							{['ve_' ve 'h'], ['ve_' ve 'v'], ['ve_' ve 'h_vel'], ['ve_' ve 'v_vel']});
						comb_sacc_tbl.ve_non_sacc_startpos_h(new_row_num) = table2array(non_sacc_data(1,1));
						comb_sacc_tbl.ve_non_sacc_endpos_h(new_row_num) = table2array(non_sacc_data(height(non_sacc_data),1));
						comb_sacc_tbl.ve_non_sacc_variancepos_h(new_row_num) = var(table2array(non_sacc_data(:,1)));
						comb_sacc_tbl.ve_non_sacc_medianpos_h(new_row_num) = median(table2array(non_sacc_data(:,1)));
						comb_sacc_tbl.ve_non_sacc_meanpos_h(new_row_num) = mean(table2array(non_sacc_data(:,1)));
						comb_sacc_tbl.ve_non_sacc_variancevel_h(new_row_num) = var(table2array(non_sacc_data(:,3)));
						comb_sacc_tbl.ve_non_sacc_medianvel_h(new_row_num) = median(table2array(non_sacc_data(:,3)));
						comb_sacc_tbl.ve_non_sacc_meanvel_h(new_row_num) = mean(table2array(non_sacc_data(:,3)));
						
						comb_sacc_tbl.ve_non_sacc_startpos_v(new_row_num) = table2array(non_sacc_data(1,2));
						comb_sacc_tbl.ve_non_sacc_endpos_v(new_row_num) = table2array(non_sacc_data(height(non_sacc_data),2));
						comb_sacc_tbl.ve_non_sacc_variancepos_v(new_row_num) = var(table2array(non_sacc_data(:,2)));
						comb_sacc_tbl.ve_non_sacc_medianpos_v(new_row_num) = median(table2array(non_sacc_data(:,2)));
						comb_sacc_tbl.ve_non_sacc_meanpos_v(new_row_num) = mean(table2array(non_sacc_data(:,2)));
						comb_sacc_tbl.ve_non_sacc_variancevel_v(new_row_num) = var(table2array(non_sacc_data(:,4)));
						comb_sacc_tbl.ve_non_sacc_medianvel_v(new_row_num) = median(table2array(non_sacc_data(:,4)));
						comb_sacc_tbl.ve_non_sacc_meanvel_v(new_row_num) = mean(table2array(non_sacc_data(:,4)));
					end
				end

				
				writetable(comb_sacc_tbl, strrep(sacc_fname, '.txt', '_comb.txt'), 'Delimiter', '\t' )
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
% 		stop_ones = strfind([sacc_mask' 0],[1 0]);
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
% 		stop_ones = strfind([msk' 0],[1 0]);
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

% if it's a vergence file, there will be a column with vergence_target_label
if any(strcmp(tbl.Properties.VariableNames, 'vergence_target_label'))
	
	verge_out_tbl = table();

	vergence_label_msk = ~cellfun(@isempty, tbl.vergence_target_label);
	if any(contains(tbl.Properties.VariableNames, 'vergence_peak_vel'))
		vergence_peak_vel_inds = find(~isnan(tbl.vergence_peak_vel));
	else
		vergence_peak_vel_inds = [];
	end
	
	% loop thru each vergence target label
	verg_target_inds = find(~cellfun(@isempty,tbl.vergence_target_label));
% 	verg_mark_inds = find(~cellfun(@isempty,tbl.vergence_marks));
	verge_tbl_row = 0;
	for v_cnt = 1:length(verg_target_inds)
		v_ind = verg_target_inds(v_cnt);
		
		% add the vergence target to the table
		verge_tbl_row = verge_tbl_row + 1;
		warning('OFF', 'MATLAB:table:RowsAddedExistingVars')
		verge_out_tbl.t_eye(verge_tbl_row) = tbl.t_eye(v_ind);
		warning('ON', 'MATLAB:table:RowsAddedExistingVars')
		
		verge_out_tbl.vergence_target_label{verge_tbl_row} = tbl.vergence_target_label{v_ind};
		verge_out_tbl.vergence_target_amplitude(verge_tbl_row) = tbl.vergence_target_amplitude(v_ind);
		verge_out_tbl.vergence_target_saccade_amplitude(verge_tbl_row) = tbl.vergence_target_saccade_amplitude(v_ind);		
		
		% find the vergence marks after the target
		if any(contains(tbl.Properties.VariableNames, 'vergence_marks'))
			verge_mark_inds = find(~cellfun(@isempty, tbl.vergence_marks(v_ind:end))) + v_ind-1;
		else
			verge_mark_inds = [];
		end
					
		% record the vergence marks after the target_ind less than 2.5 sec
		% after the vergence target
		while length(verge_mark_inds) > 1
			% find both the begin & end vergence marks
			bb_ind = find(contains({tbl.vergence_marks{verge_mark_inds}},'begin'),1);
			vm_beg_ind = verge_mark_inds(bb_ind);
			ee_ind = find(contains({tbl.vergence_marks{verge_mark_inds}},'end'),1);
			vm_end_ind = verge_mark_inds(ee_ind);	
			% times between vergence targets are > 2 s
			if tbl.t_eye(vm_beg_ind) - tbl.t_eye(v_ind) < 2.5
				% add begin vergence info to verge_out_tbl

				% which eye has the vergence mark
				tmp = regexp(tbl.vergence_marks{vm_beg_ind}, '(r.)|(l.)', 'match');
				eye_chan = tmp{1};
				if strncmp(eye_chan, 'r', 1)
					other_eye_chan = strrep(eye_chan, 'r', 'l');
				else
					other_eye_chan = strrep(eye_chan, 'l', 'r');
				end
				if strncmp(eye_chan, ve, 1)
					eye_chan = ['ve_' eye_chan]; %#ok<*AGROW>
					other_eye_chan = ['nve_' other_eye_chan];
				else
					eye_chan = ['nve_' eye_chan ];
					other_eye_chan = ['ve_' other_eye_chan];
				end
% 					verge_out_tbl.(eye_chan){verge_tbl_row} = eye_chan;

				% latency of begin 
				eye_latency_var = ['begin_latency_' eye_chan];
				verge_out_tbl.(eye_latency_var)(verge_tbl_row) = tbl.t_eye(vm_beg_ind) - tbl.t_eye(v_ind);
				% latency of end 
				eye_latency_var = ['end_latency_' eye_chan];
				verge_out_tbl.(eye_latency_var)(verge_tbl_row) = tbl.t_eye(vm_end_ind) - tbl.t_eye(v_ind);

				% amplitude
				verge_out_tbl.vergence_amplitude(verge_tbl_row) = tbl.vergence(vm_end_ind) - tbl.vergence(vm_beg_ind);

				% eye_chan peak velocity
				[~, tmp_ind] = nanmax(abs(tbl.([eye_chan '_vergence_calibrated_velocity'])(v_ind:vm_end_ind)));
				peak_vel_ind = tmp_ind  + v_ind -1;
				verge_out_tbl.(['t_' eye_chan '_eye_verge_cal_peak_vel'])(verge_tbl_row) = tbl.t_eye(peak_vel_ind);
				verge_out_tbl.([eye_chan '_eye_verge_cal_peak_vel'])(verge_tbl_row) = tbl.([eye_chan '_vergence_calibrated_velocity'])(peak_vel_ind);
				% other_eye_chan peak velocity
				[~, tmp_ind] = nanmax(abs(tbl.([other_eye_chan '_vergence_calibrated_velocity'])(v_ind:vm_end_ind)));
				peak_vel_ind = tmp_ind  + v_ind -1;
				verge_out_tbl.(['t_' other_eye_chan '_eye_verge_cal_peak_vel'])(verge_tbl_row) = tbl.t_eye(peak_vel_ind);
				verge_out_tbl.([other_eye_chan '_eye_verge_cal_peak_vel'])(verge_tbl_row) = tbl.([other_eye_chan '_vergence_calibrated_velocity'])(peak_vel_ind);
				
				% find the vegence peak velocity
% 				v_peak_vel_ind = find(vergence_peak_vel_inds > v_ind, 1, 'first');
				[~, tmp_ind] = nanmax(abs(tbl.vergence_peak_vel(v_ind:vm_end_ind)));
				peak_vel_ind = tmp_ind  + v_ind -1;
				if ~isempty(peak_vel_ind)
					verge_out_tbl.t_vergence_peak_vel(verge_tbl_row) = tbl.t_eye(peak_vel_ind);
					verge_out_tbl.vergence_peak_vel(verge_tbl_row) = tbl.vergence_peak_vel(peak_vel_ind);
				end
				
				% saccade variables in the tbl
				tmp = regexpi(tbl.Properties.VariableNames, '.*saccades$', 'match');
				sacc_var_list = [tmp{:}];

				for sv_cnt = 1:length(sacc_var_list)
					% find the saccades after the target
					sacc_var = sacc_var_list{sv_cnt};
					sacc_inds = find(~cellfun(@isempty, tbl.(sacc_var)));
					ss_inds = find(tbl.t_eye(sacc_inds)-tbl.t_eye(v_ind)<2 & tbl.t_eye(sacc_inds)-tbl.t_eye(v_ind)>0);
					sv_inds = sacc_inds(ss_inds);
					
					sbeg_cnt = 0;
					send_cnt = 0;
					for sv_cnt = 1:length(sv_inds)
						if contains(tbl.(sacc_var)(sv_inds(sv_cnt)), 'start')
							sbeg_cnt = sbeg_cnt+1;
							verg_t_var = [sacc_var '_' num2str(sbeg_cnt) '_start_t'];
							tmp = regexp(sacc_var, '(nve|ve)_(l|r)(v|h)', 'match');
							tbl_eye_pos_var = [tmp{1} '_vergence_calibrated'];
							verge_eye_pos_var = [sacc_var '_' num2str(sbeg_cnt) '_verge_cal_start_pos'];
						else
							send_cnt = send_cnt+1;
							verg_t_var = [sacc_var '_' num2str(send_cnt) '_end_t'];
							tmp = regexp(sacc_var, '(nve|ve)_(l|r)(v|h)', 'match');
							tbl_eye_pos_var = [tmp{1} '_vergence_calibrated'];
							verge_eye_pos_var = [sacc_var '_' num2str(send_cnt) '_verge_cal_end_pos'];
						end				
						if any(contains(tbl.Properties.VariableNames, tbl_eye_pos_var))
							verge_out_tbl.(verg_t_var)(verge_tbl_row) = tbl.t_eye(sv_inds(sv_cnt));
							verge_out_tbl.(verge_eye_pos_var)(verge_tbl_row) = tbl.(tbl_eye_pos_var)(sv_inds(sv_cnt));
						end
					end
				end		
				
				% remove these verge_mark_inds	from the list	
				verge_mark_inds(ee_ind) = [];
				verge_mark_inds(bb_ind) = [];
			else
				break
			end
			
			
		end % while there are verge_mark_inds to check
		
		
	end % for loop through verge targets

	
	writetable(verge_out_tbl, strrep(fname, '.txt', '_vergence.txt'), 'delimiter', '\t')
end
fclose(fid); % summary file






