function nonoverlap_inds = find_nonoverlapping_saccades(sacc_tbl, other_sacc_tbl)
% return indices into sacc_tbl for all saccades that do not overlap/cooincide with
% saccades in the other table 

nonoverlap_inds = [];

for sacc_cnt = 1:height(sacc_tbl)
	found_overlap = false;
	for os_cnt = 1:height(other_sacc_tbl)
		if (sacc_tbl.startTime(sacc_cnt) >= other_sacc_tbl.startTime(os_cnt) && ...
				sacc_tbl.startTime(sacc_cnt) <= other_sacc_tbl.endTime(os_cnt)) || ...
			(other_sacc_tbl.startTime(os_cnt) >= sacc_tbl.startTime(sacc_cnt) && ...
				other_sacc_tbl.startTime(os_cnt) <= sacc_tbl.endTime(sacc_cnt))	
			found_overlap = true;
			break
		end
	end % each row in other tbl
	
	if ~found_overlap
		nonoverlap_inds = [nonoverlap_inds sacc_cnt];
	end
end % each row in sacc_tbl
return