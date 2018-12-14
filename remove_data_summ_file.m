function remove_data_summ_file(summ_filename, excl_beg_t, excl_end_t)

data = readtable(summ_filename, 'delimiter', '\t');

rows = find(data.startTime >= excl_beg_t & data.startTime <= excl_end_t);


data(rows,:) = [];
		
writetable(data, summ_filename, 'delimiter', '\t')

