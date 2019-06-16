function other_eye_nonoverlap_inds = find_other_eye_nonoverlapping_saccades(sacc_tbl, other_sacc_tbl)
% return indices into other_sacc_tbl for all saccades that do not overlap/cooincide with
% saccades in sacc_table 

other_eye_nonoverlap_inds = [];

for row = 1:height(other_sacc_tbl)
% 	found_overlap = false;
% 	for sacc_cnt = 1:height(sacc_tbl)
% 		if (other_sacc_tbl.endTime(os_cnt) >= sacc_tbl.startTime(sacc_cnt) && ...
% 				other_sacc_tbl.endTime(os_cnt) <= sacc_tbl.endTime(sacc_cnt)) || ...
% 			(other_sacc_tbl.startTime(os_cnt) >= sacc_tbl.startTime(sacc_cnt) && ...
% 				other_sacc_tbl.startTime(os_cnt) <= sacc_tbl.endTime(sacc_cnt))	
% 			found_overlap = true;
% 			break
% 		end
% 	end % each row in sacc_tbl

	overlap_ind = find((sacc_tbl.startTime >= other_sacc_tbl.startTime(row) & sacc_tbl.endTime <= other_sacc_tbl.endTime(row)) | ...
						(sacc_tbl.endTime > other_sacc_tbl.startTime(row) & sacc_tbl.endTime <= other_sacc_tbl.endTime(row)) | ...
						(sacc_tbl.startTime >= other_sacc_tbl.startTime(row) & sacc_tbl.startTime < other_sacc_tbl.endTime(row)) | ...
						(sacc_tbl.startTime <= other_sacc_tbl.startTime(row) & sacc_tbl.endTime >= other_sacc_tbl.endTime(row)), 1);
	if isempty(overlap_ind)
		other_eye_nonoverlap_inds = [other_eye_nonoverlap_inds row];
	end
end % each row in other_sacc_tbl
return