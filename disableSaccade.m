function disableSaccade(source, callbackdata)
handles = guidata(gcf);
axes(handles.axes_eye)

% find the saccade lines for the corresponding tag like
% (saccade_lh_#38_end)
saccade_tag = strrep(source.Tag, 'menu_', '');
saccade_tag_no_beg_end = strrep(saccade_tag, '_begin', '');
srch_str = ['^' saccade_tag_no_beg_end '_((begin)|(end))$'];
saccade_beg_end_lines = findobj(handles.axes_eye, '-regexp', 'Tag', srch_str);
% change the marker style 
set(saccade_beg_end_lines, 'Marker', 'x')

% and the line in between begin & end markers
srch_str = ['^' saccade_tag_no_beg_end '$' ];
saccade_line = findobj(handles.axes_eye, '-regexp', 'Tag', srch_str);
% change the marker style 
set(saccade_line, 'LineStyle',':') 

% set the menu to enable
set(source, 'Label', 'Enable Saccade', 'Callback', @enableSaccade)

return