function data = get_apdm_data(filename)
%
%
%


% get the file version
file_version = h5readatt(filename, '/', 'FileFormatVersion');

switch file_version
	case 4
		% annotations
		annotation_struct = h5read(filename, '/Annotations');
		% .Time (Microseconds since 0:00 Jan 1, 1970, UTC), .DeviceID, .Annotation
		
		monitorCaseIDList = h5readatt(filename, '/', 'CaseIdList');
		monitorLabelList = h5readatt(filename, '/', 'MonitorLabelList');
		for iMonitor = 1:length(monitorCaseIDList)
			caseID = remove_non_chars(monitorCaseIDList{iMonitor});
			monitorLabelList{iMonitor} = remove_non_chars(monitorLabelList{iMonitor});
			%     if ~isempty(useMonitorLabels) && isempty(strmatch(monitorLabel, useMonitorLabels, 'exact'))
			%         continue;
			%     end
			
			timePath = ['/' caseID '/Time'];
			data.time = h5read(filename, timePath);
			
			data.sensor{iMonitor} = monitorLabelList{iMonitor};
			
			data.accel{iMonitor} = h5read(filename, ['/' caseID '/Calibrated/Accelerometers']);
			data.gyro{iMonitor} = h5read(filename, ['/' caseID '/Calibrated/Gyroscopes']);
			data.mag{iMonitor} = h5read(filename, ['/' caseID '/Calibrated/Magnetometers']);
			data.orient{iMonitor} = h5read(filename, ['/' caseID '/Calibrated/Orientation']);
			
		end
		
		data = process_annots_and_time(data, annotation_struct);
		
	case 5
		% annotations
		annotation_struct = h5read(filename, '/Annotations');
		% .Time (Microseconds since 0:00 Jan 1, 1970, UTC), .SensorID, .Annotation
		
		sensor_list = {'1262', '1338', '1383'}; % hard coded sensor numbers - how can we get the sensor numbers from the file?
		
% 		label_list = {'head', 'l_hand', 'r_hand'}; % also hard coded labels
		% time seems to be exactly the same for all 3 sensors, so just store 1
		data.time = h5read(filename, ['/Sensors/' sensor_list{1} '/Time']);
		for sensor_idx = 1:length(sensor_list)
			% get label from the sensor configuration

% 			data.sensor{sensor_idx} = label_list{sensor_idx}; % can we get the label from the h5 file?
			data.sensor{sensor_idx} =  remove_non_chars(h5readatt(filename, ['/Sensors/' sensor_list{sensor_idx} '/Configuration'],'Label 0'));  % get label from the sensor configuration
			data.accel{sensor_idx} = h5read(filename, ['/Sensors/' sensor_list{sensor_idx} '/Accelerometer']);
			data.gyro{sensor_idx} = h5read(filename, ['/Sensors/' sensor_list{sensor_idx} '/Gyroscope']);
			data.mag{sensor_idx} = h5read(filename, ['/Sensors/' sensor_list{sensor_idx} '/Magnetometer']);
			data.orient{sensor_idx} = h5read(filename, ['/Processed/' sensor_list{sensor_idx} '/Orientation']);
		end
		
		data = process_annots_and_time(data, annotation_struct);
		
	otherwise
		error('h5 file format version %d is not handled', file_version)
end
return
end % get_hdf_data

% ------------------------------------------------------------
function out = remove_non_chars(in)
tmp = double(in);
tmp = tmp(tmp > 32);
out = char(tmp);
return
end

function data = process_annots_and_time(data, annotation_struct)
% annotations
t_beg = double(data.time(1));
for an_num = 1:length(annotation_struct.Time)
	annot_time = double(annotation_struct.Time(an_num));
	annot_rel_time = (annot_time - t_beg) / 1e6;
	data.annot{an_num}.time = annot_rel_time;
	
	tmp = annotation_struct.Annotation(:,an_num)';
	data.annot{an_num}.msg = remove_non_chars(tmp);
	fprintf('t=%f, %s\n', annot_rel_time, data.annot{an_num}.msg);
	
end

% make time start at zero
data.time = (double(data.time) - t_beg) ./ 1e6;
return
end
