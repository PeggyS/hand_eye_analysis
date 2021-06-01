function handles = get_page_text_image(handles)
% get the image of the text displayed and the time when it was drawn

% the '_#' in the file name to determine the default image name
tmp = regexp(handles.bin_filename, '_\d+.bin', 'match');
underscore_num = strrep(tmp{1}, '.bin', '');
num = strrep(underscore_num, '_', '');
% find od, os, or ou in path
tmp = regexpi(handles.bin_filename, '(od)|(os)|(ou)/', 'match');
try
   eye = strrep(lower(tmp{1}), '/', '');
catch
   beep;pause(0.33);beep;pause(0.33);beep
   fprintf('I could not determine which eye to use.\n');
   fprintf('It should be included in the name of the data file.\n');
   fprintf('Type "dbquit" to exit debugger.\n');
   keyboard
   return
end

page_fname = [eye num '.jpg'];
[pathstr, ~, ~] = fileparts(handles.bin_filename);


% get the text page image 
if exist(fullfile(pathstr, page_fname),'file') % if it's in the same folder as the data
	handles.img_file = fullfile(pathstr, page_fname);
   try
      handles.im_data = imread(handles.img_file);
   catch
   fprintf('I could not read the image file.\n');
   fprintf('Type "dbquit" to exit debugger.\n');
   keyboard
   return
   end
   
else
	% go up 2 folder levels and look for the file
	[pathname,filename] = findfilepath(page_fname, '../..');
	if isempty(pathname)
		% request file location
			disp('choose image file ...')
			[fnImg, pnImg] = uigetfile({'*.*'}, 'Choose image file ...');
			if isequal(fnImg,0) || isequal(pnImg,0)
				disp('no image file')
				return
			else
				handles.img_file = fullfile(pnImg,fnImg);
				handles.im_data = imread(handles.img_file);
			end
	else
		handles.img_file = fullfile(pathname,filename);
		handles.im_data = imread(handles.img_file);
	end
end

return % get_page_text_image