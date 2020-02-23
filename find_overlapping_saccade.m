function ol_sacc_ind = find_overlapping_saccade(sacc_start, sacc_end, ol_sacclist)
% given the sacc start & sacc end, find the matching or overlapping saccade
% in ol_sacclist. return the index into ol_sacclist
ol_sacc_ind = [];

% find index in ol_sacclist gt sacc_start
ind_start = find(ol_sacclist.start >= sacc_start, 1, 'first');
if ol_sacclist.start(ind_start) >= sacc_start && ol_sacclist.start(ind_start) <= sacc_end
	ol_sacc_ind = ind_start;
	return
end

% find index in ol_sacclist lt sacc_end
ind_end = find(ol_sacclist.end <= sacc_end, 1, 'last');
if ol_sacclist.end(ind_end) >= sacc_start && ol_sacclist.end(ind_end) <= sacc_end
	ol_sacc_ind = ind_end;
	return
end

% if ind_end == ind_start, then the ol_sacclist(ind_) is fully contained
% within the sent saccade
if ind_end == ind_start
	ol_sacc_ind = ind_start;
	return
end

