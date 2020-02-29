function ol_sacc_ind = find_overlapping_saccade(sacc_start, sacc_end, ol_sacclist)
% given the sacc start & sacc end, find the matching or overlapping saccade
% in ol_sacclist. return the index into ol_sacclist
ol_sacc_ind = [];

% saccade start within the list of saccades
% find index in ol_sacclist gt sacc_start
ind_start = find(ol_sacclist.start <= sacc_start, 1, 'last');
if ~isempty(ind_start)
	if ol_sacclist.start(ind_start) <= sacc_start && ol_sacclist.end(ind_start) >= sacc_start
		ol_sacc_ind = ind_start;
 		return
	end
end
% find index in ol_sacclist lt sacc_start
ind_start = find(ol_sacclist.start >= sacc_start, 1, 'first');
if ~isempty(ind_start)
	if ol_sacclist.start(ind_start) >= sacc_start && ol_sacclist.start(ind_start) <= sacc_end
		ol_sacc_ind = ind_start;
 		return
	end
end


return
