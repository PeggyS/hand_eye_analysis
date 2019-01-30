function labelSaccade(source, callbackdata, label_str)
handles = guidata(gcf);
axes(handles.axes_eye)

% find the saccade lines for the corresponding tag 
h_sacc_line = findobj(source.Parent.Parent, 'Tag', strrep(source.Tag, 'menu_', ''));
% update the menu
if strcmp(source.Checked, 'off')
	h_other = findobj(source.Parent, 'Tag', source.Tag);
	set(h_other, 'Checked', 'off')
	source.Checked = 'on';
	% make the saccade marker filled , 'markerfacecolor', beg_line_color
	
	h_sacc_line.MarkerFaceColor = h_sacc_line.Color;
else
	source.Checked = 'off';
	h_sacc_line = findobj(source.Parent.Parent, 'Tag', strrep(source.Tag, 'menu_', ''));
	h_sacc_line.MarkerFaceColor = 'none';
end

saccade_beg_line = h_sacc_line;

saccade_tag = h_sacc_line.Tag;

% which channel of data
tmp = regexp(saccade_tag, '(lh)|(rh)|(lv)|(rv)', 'match');
try
	eye_chan = tmp{1};
catch
	fname = ['labelSaccade eye_chan error ' datestr(now)];
	save(fname)
	beep
	disp('*********')
	disp('Error finding saccade line by tag')
	disp(['Send the file ' fname ' to Peggy.'])
	disp('*********')
end

% source of saccades
tmp = regexp(saccade_tag, '(engbert)|(findsaccs)|(eyelink)', 'match');
sacc_source = tmp{1};
if strcmp(sacc_source, 'eyelink')
	sacc_source = 'EDF_PARSER';
end

% index of the saccade source
sacc_source_ind = 0;
for cnt = 1:length(handles.eye_data.(eye_chan).saccades)
	if strcmp(handles.eye_data.(eye_chan).saccades(cnt).paramtype, sacc_source)
		sacc_source_ind = cnt;
	end
end

sacc_starts = (handles.eye_data.(eye_chan).saccades(sacc_source_ind).sacclist.start-handles.eye_data.start_times)/1000;

% index of matching saccade
sacc_ind = find(abs(sacc_starts-saccade_beg_line.XData) < eps);
assert(length(sacc_ind)==1, 'error finding saccade begin time in sacclist.start')

if ~isfield(handles.eye_data.(eye_chan).saccades(sacc_source_ind).sacclist, 'label')
	handles.eye_data.(eye_chan).saccades(sacc_source_ind).sacclist.label ...
		= cell(size(handles.eye_data.(eye_chan).saccades(sacc_source_ind).sacclist.start));
end

if strcmp(source.Checked, 'off')
	handles.eye_data.(eye_chan).saccades(sacc_source_ind).sacclist.label{sacc_ind}='';
else
	handles.eye_data.(eye_chan).saccades(sacc_source_ind).sacclist.label{sacc_ind}=label_str;
end


guidata(handles.figure1, handles)
return