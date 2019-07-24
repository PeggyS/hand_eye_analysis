function [out_words, wbound_boxes] = generate_read_page_rois(page_img)
% Take an image of a page of text, OCR it, then make the word bounding boxes 
% large enough so that there is no space between words


page = imread(page_img);

ocr_results = ocr(page);
wbound_boxes = ocr_results.WordBoundingBoxes;
out_words = ocr_results.Words;

% bounding boxes are pixel values
% (0,0) of image is upper left

num_words = length(ocr_results.Words);


% work on each line of text

% index of last word in each line of text
end_line_ind = find(diff(wbound_boxes(:,1))<0);
mean_above_change_per_line = zeros(1,length(end_line_ind));
mean_below_change_per_line = zeros(1,length(end_line_ind));

% each line (except 1st & last)
start_ind = 1;
for l_cnt = 1:length(end_line_ind)
	% bottom pixel of line above
	bot_line_above = mean(wbound_boxes(start_ind:end_line_ind(l_cnt), 2) + ...
		wbound_boxes(start_ind:end_line_ind(l_cnt), 4));

	% top of line below	
	if l_cnt <  length(end_line_ind)
		end_ind = end_line_ind(l_cnt+1);
	else
		end_ind = size(wbound_boxes,1);
	end

	top_line_below = mean(wbound_boxes(end_line_ind(l_cnt)+1:end_ind, 2));
	
	% halfway between them
	mid_point = round((bot_line_above + top_line_below)/2);
	
	% change above line's box height to make bottom of box on the mid_point
	below_change = mid_point - wbound_boxes(start_ind:end_line_ind(l_cnt), 2);
	wbound_boxes(start_ind:end_line_ind(l_cnt), 4) = below_change;
	mean_below_change_per_line(l_cnt) = mean(below_change);
	
	
	% change below line's y pos & height to make the y pos start at
	% midpoint and bottom of box at it's original position
	above_change = wbound_boxes(end_line_ind(l_cnt)+1:end_ind, 2) - mid_point;
	wbound_boxes(end_line_ind(l_cnt)+1:end_ind, 4) = ...
		wbound_boxes(end_line_ind(l_cnt)+1:end_ind, 4) + above_change;
	mean_above_change_per_line(l_cnt) = mean(above_change);
	
	n_words = end_ind - end_line_ind(l_cnt);
	
	wbound_boxes(end_line_ind(l_cnt)+1:end_ind, 2) = mid_point*ones(n_words,1);
	
	start_ind = end_line_ind(l_cnt) + 1;
	
	page_w_boxes = insertShape(page, 'Rectangle', wbound_boxes, 'Color', 'Red');
	imshow(page_w_boxes)
end

% adjust the first line top using the mean above change
mean_above_change = round(mean(mean_above_change_per_line));
n_words = end_line_ind(1);
top_of_box = round(mean(wbound_boxes(1:end_line_ind(1), 2))) - mean_above_change;
wbound_boxes(1:end_line_ind(1), 2) = top_of_box * ones(n_words,1);
height_of_boxes = wbound_boxes(end_line_ind(2), 2) - top_of_box; % top of next line minus top of line
wbound_boxes(1:end_line_ind(1), 4) = height_of_boxes * ones(n_words,1);


page_w_boxes = insertShape(page, 'Rectangle', wbound_boxes, 'Color', 'Red');
imshow(page_w_boxes)
	
% adjust the last line bottom using the mean height of all other lines
mean_height = round(mean(wbound_boxes(1:end_line_ind(end),4)));
wbound_boxes(end_line_ind(end)+1:end, 4) = mean_height*ones(size(wbound_boxes(end_line_ind(end)+1:end, 4)));

page_w_boxes = insertShape(page, 'Rectangle', wbound_boxes, 'Color', 'Red');
imshow(page_w_boxes)


% adjust boxes between words on each line
adj_left_first_word = 5;
adj_right_last_word = 5;

for w_cnt = 1:num_words
	% adjust left side of box
	if w_cnt == 1 || sum(end_line_ind+1-w_cnt==0) % 1st word in a line
		wbound_boxes(w_cnt, 1) = wbound_boxes(w_cnt, 1) - adj_left_first_word;
		wbound_boxes(w_cnt, 3) = wbound_boxes(w_cnt, 3) + adj_left_first_word;
	else
		incr_to_move = wbound_boxes(w_cnt, 1) - (wbound_boxes(w_cnt-1, 1) + wbound_boxes(w_cnt-1, 3));
		wbound_boxes(w_cnt, 3) = wbound_boxes(w_cnt, 3) + incr_to_move;
		wbound_boxes(w_cnt, 1) = wbound_boxes(w_cnt, 1) - incr_to_move;
		
	end
	
	if w_cnt == num_words || sum(end_line_ind-w_cnt==0) % last word in a line
		wbound_boxes(w_cnt, 3) = wbound_boxes(w_cnt, 3) + adj_right_last_word;
	else % word mid-line
		mid_word = round((wbound_boxes(w_cnt,1) + wbound_boxes(w_cnt,3) + wbound_boxes(w_cnt+1,1)) / 2);
		wbound_boxes(w_cnt, 3) = mid_word - wbound_boxes(w_cnt,1);
	end
	
end

page_w_boxes = insertShape(page, 'Rectangle', wbound_boxes, 'Color', 'Red');
imshow(page_w_boxes)
imwrite(page_w_boxes, strrep(page_img, '.jpg', '_word_boxes.jpg'), 'JPEG')