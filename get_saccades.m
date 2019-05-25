function handles = get_saccades(handles, sacc_type_str)
% read in saccades from a mat file created with saccades_gui and put the
% saccades in the handles.eye_data struct

% the default saccade file name
sacc_fname = strrep(handles.bin_filename, '.bin', ['_' sacc_type_str '.mat']);

if ~exist(sacc_fname, 'file')
	disp(['Choose ' sacc_type_str ' saccade .mat file ...'])
	[fnSave, pnSave] = uigetfile({'*.mat'}, 'Choose saccade file ...');
	if isequal(fnSave,0) || isequal(pnSave,0)
	   disp('no  file chosen ... ')
	   return
	end
	sacc_fname = fullfile(pnSave, fnSave);
end

sacc = load(sacc_fname);

e_list = {'lh', 'rh', 'lv', 'rv'};
for e_cnt = 1:length(e_list)
	eye_str = e_list{e_cnt};
	if isfield(sacc.data, eye_str)
		num_sacc_types = length(handles.eye_data.(eye_str).saccades);
		% add this new type
		handles.eye_data.(eye_str).saccades(num_sacc_types+1).paramtype = sacc_type_str;
		handles.eye_data.(eye_str).saccades(num_sacc_types+1).params = sacc.params;
		handles.eye_data.(eye_str).saccades(num_sacc_types+1).sacclist = sacc.data.(eye_str).sacclist;		
	end
end % each type of eye data present

for e_cnt = 1:length(e_list)
	eye_str = e_list{e_cnt};
	if isfield(sacc.data, eye_str)
		if ~isfield(handles.eye_data.(eye_str).saccades(num_sacc_types+1).sacclist, 'swj')
				% swj is not a field, add it
				handles.eye_data = square_wave_jerk_detect(handles.eye_data);
		end % swj is not a field
	end
end
return % get_saccades