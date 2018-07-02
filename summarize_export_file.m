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
excl_match_cell = regexp(tbl.annotation, '.*exclud.*');
excl_inds = find(~cellfun(@isempty,excl_match_cell));

excluded_time = 0;
found_excl_beg = 0;

for ex_cnt = 1:length(excl_inds)
	if strncmp(tbl.annotation(excl_inds(ex_cnt)), 'beg', 3)
		exclude_beg_time = tbl.t_eye(excl_inds(ex_cnt));
		found_excl_beg = 1;
	end
	if strncmp(tbl.annotation(excl_inds(ex_cnt)), 'end', 3)
		if ~found_excl_beg
			warning('found exclusion end without a beginning')
		else
			exclude_end_time = tbl.t_eye(excl_inds(ex_cnt));
			excluded_time = excluded_time + (exclude_end_time - exclude_beg_time);
			found_excl_beg = 0;
		end
	end
end


out_fname = strrep(fname, '.txt', '_summary.txt');

fid = fopen(out_fname, 'w');
fprintf(fid, 'total time  = %g\n', time_in_file);
fprintf(fid, 'excluded time = %g\n', excluded_time);






