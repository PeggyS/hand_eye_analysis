function overlap_inds = find_overlapping_saccades(sacc_tbl, other_sacc_tbl)
% return indices into sacc_tbl (col 1) for all saccades that overlap/cooincide with
% saccades in the other table (col 2)

overlap_inds = [];

for sacc_cnt = 1:height(sacc_tbl)
	for os_cnt = 1:height(other_sacc_tbl)
		if (sacc_tbl.startTime(sacc_cnt) >= other_sacc_tbl.startTime(os_cnt) && ...
				sacc_tbl.startTime(sacc_cnt) <= other_sacc_tbl.endTime(os_cnt)) || ...
			(other_sacc_tbl.startTime(os_cnt) >= sacc_tbl.startTime(sacc_cnt) && ...
				other_sacc_tbl.startTime(os_cnt) <= sacc_tbl.endTime(sacc_cnt))	
			overlap_inds = [overlap_inds; sacc_cnt, os_cnt];
			break
		end
		
	end % each row in other tbl
end % each row in sacc_tbl
return