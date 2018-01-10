function [beg_t, end_t] = find_data_with_n_humps(time, data, num_humps, start_time)
% find the start & end time of data with the given number of humps 

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
peak_ind = find(diff(sign_vec) < 0);

found_humps = length(peak_ind);

% hump_peaks = data(peak_ind);
time_peaks = time(peak_ind);

% the largest n humps
largest_peak_ind = [];
for nn = 1:min(num_humps, found_humps)
	[~, ind] = min(abs(time_peaks-start_time));
% 	[~, ind] = max(hump_peaks);
	largest_peak_ind(nn) = peak_ind(ind);
% 	hump_peaks(ind) = -inf;
	time_peaks(ind) = inf;
end

% find the mins/troughs before and after the peaks
trough_ind = find(diff(sign_vec) > 0);
inds = trough_ind(trough_ind < min(largest_peak_ind));
if isempty(inds)
	beg_ind = 1;
else
	beg_ind = inds(end);
end

inds = trough_ind(trough_ind > max(largest_peak_ind));
if isempty(inds)
	end_ind = length(data);
else
	end_ind = inds(1);
end

beg_t = time(beg_ind);
end_t = time(end_ind);
return
