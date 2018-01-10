function found_humps = find_num_humps(time, data)
% find the number of humps in the data vector

% filter the data
samp_freq = 1/mean(diff(time));

fc = 2;
filt_data = lpf(data, 4, fc, samp_freq);

found_humps = 0;
diff_data = diff(filt_data);

% since the point by point deriv may never get very close to zero, 
% count the sign changes in the deriv/diff vector
sign_vec = sign(diff_data);  % < 0 -> -1; > 0 -> +1; == 0 -> 0

% indices of sign changes from pos to neg -> peaks
chng_ind = find(diff(sign_vec) < 0);

found_humps = length(chng_ind);

return




