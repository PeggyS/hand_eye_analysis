function enableSaccade(source, callbackdata)
handles = guidata(gcf);
axes(handles.axes_eye)

% find the saccade lines for the corresponding tag like
% (saccade_lh_#38_end)
saccade_tag = strrep(source.Tag, 'menu_', '');
saccade_tag_no_beg_end = strrep(saccade_tag, '_begin', '');
srch_str = ['^' saccade_tag_no_beg_end '_((begin)|(end))$'];
saccade_beg_end_lines = findobj(handles.axes_eye, '-regexp', 'Tag', srch_str);
% change the marker style 
set(saccade_beg_end_lines, 'Marker', 'o')

% and the line in between begin & end markers
srch_str = ['^' saccade_tag_no_beg_end '$' ];
saccade_line = findobj(handles.axes_eye, '-regexp', 'Tag', srch_str);
% change the marker style 
set(saccade_line, 'LineStyle','-') 

% set the menu to enable
set(source, 'Label', 'Disable Saccade', 'Callback', @disableSaccade)

% save the disabled state in the handles.eye_data stuct
srch_str = ['^' saccade_tag_no_beg_end '_(begin)$'];
saccade_beg_line = findobj(handles.axes_eye, '-regexp', 'Tag', srch_str);


% source of saccades
tmp = regexp(saccade_tag, '(engbert)|(findsaccs)|(eyelink)|(cluster)', 'match');
sacc_source = tmp{1};
if strcmp(sacc_source, 'eyelink')
	sacc_source = 'EDF_PARSER';
end

tmp = regexp(saccade_tag, '(lh)|(rh)|(lv)|(rv)', 'match');
try
	eye_chan = tmp{1};
catch
	fname = ['disableSaccade eye_chan error ' datestr(now)];
	save(fname)
	beep
	disp('*********')
	disp('Error finding disabled saccade line by tag')
	disp(['Send the file ' fname ' to Peggy.'])
	disp('*********')
end

% index of the saccade source
sacc_source_ind = 0;
for cnt = 1:length(handles.eye_data.(eye_chan).saccades)
	if strcmp(handles.eye_data.(eye_chan).saccades(cnt).paramtype, sacc_source)
		sacc_source_ind = cnt;
	end
end

sacc_starts = (handles.eye_data.lh.saccades(sacc_source_ind).sacclist.start-handles.eye_data.start_times)/1000;

% index of matching saccade
[~, sacc_ind] = min(abs(sacc_starts-saccade_beg_line.XData));

assert(~isempty(sacc_ind), 'did not find index of saccade to disable')

handles.eye_data.(eye_chan).saccades(sacc_source_ind).sacclist.enabled(sacc_ind)=1;

guidata(handles.figure1, handles)
return