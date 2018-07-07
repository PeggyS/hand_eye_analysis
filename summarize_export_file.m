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
			excluded_time_total = excluded_time_total + (exclude_end_time - exclude_beg_time);
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
		end
	end % sacc_source
end % sacc_type

fclose(fid);






