function out_sacc_data = remove_disabled_saccades(in_sacc_data, h_ax, sacc_type)

% saccades
sacc_type_list = {'lh' 'lv' 'rh' 'rv'};
sacc_source_list = {'eyelink', 'findsaccs', 'engbert'};
for ss_cnt = 1:length(sacc_source_list)
	for st_cnt = 1:length(sacc_type_list)
		sacc_type = [sacc_source_list{ss_cnt} '_' sacc_type_list{st_cnt}];
		sacc_beg_lines = findobj(handles.axes_eye, '-regexp', 'Tag', ['saccade_' sacc_type '.*_begin$']);
		if ~isempty(sacc_beg_lines)
			% add column in table for this type of saccade
			out_tbl.([sacc_type '_saccades']) = cell(height(out_tbl), 1);
			out_tbl.([sacc_type '_saccades_labels']) = cell(height(out_tbl), 1);
			for sac_num = 1:length(sacc_beg_lines)
				if strcmp(sacc_beg_lines(sac_num).Marker, 'o') % it's enabled 'o', not disabled 'x'
					beg_t = sacc_beg_lines(sac_num).XData;
					beg_line_tag = sacc_beg_lines(sac_num).Tag;
					end_line_tag = strrep(beg_line_tag, 'begin', 'end');
					end_line = findobj(handles.axes_eye, 'Tag', end_line_tag);
					end_t = end_line.XData;
					% put the line tag into the table
					beg_row = find(out_tbl.t_eye >= beg_t, 1, 'first');
					out_tbl.([sacc_type '_saccades']){beg_row} = beg_line_tag;
					
					end_row = find(out_tbl.t_eye >= end_t, 1, 'first');
					out_tbl.([sacc_type '_saccades']){end_row} = end_line_tag;
					
					% find the label menus for this beg_saccade & add a the label if checked
					h_menus = findobj(handles.axes_eye.Parent, 'Tag',  strrep(sacc_beg_lines(sac_num).Tag, 'saccade', 'menu_saccade'));
					for m_cnt = 1:length(h_menus)
						if strcmp(h_menus(m_cnt).Checked, 'on')
							out_tbl.([sacc_type '_saccades_labels']){beg_row} = h_menus(m_cnt).Label;
							out_tbl.([sacc_type '_saccades_labels']){end_row} = h_menus(m_cnt).Label;
						end
					end
					
					
					
				end
			end % loop through each sacc_beg_line
		end % if beg lines is not empty
	end % st_cnt
end % ss_cnt