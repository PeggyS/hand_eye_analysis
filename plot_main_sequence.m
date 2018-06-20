function plot_main_sequence(varargin)

% input parameters
%	file - file of Engbert Saccade Summary xlsx

% define input parser
p = inputParser;
p.addParameter('file', '', @isstr);
p.addParameter('type', 'as', @isstr);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if isempty(inputs.file)		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick an Engbert Saccade Summary txt file');
	if isequal(fname,0) || isequal(pathname,0)
		disp('User canceled. Exitting')
		return
	else
		filePathName = fullfile(pathname,fname);
	end
else
	filePathName = inputs.file;
end

% read in the file
disp(['reading in ' filePathName '...'])
data = readtable(filePathName);

switch inputs.type
	case 'as'
		amp_h_var = 'asAmplH';
		vel_h_var = 'asPeakVelH';
		amp_v_var = 'asAmplV';
		vel_v_var = 'asPeakVelV';
	case 'eng'
		amp_h_var = 'hAmpl';
		vel_h_var = 'hPeakVelComponent';
		amp_v_var = 'vAmpl';
		vel_v_var = 'vPeakVelComponent';
end

figure('Position', [1000         543         524         795]);

subplot(2,1,1)
if ismember(amp_h_var, data.Properties.VariableNames) && ismember(vel_h_var, data.Properties.VariableNames)
	do_main_seq(data.(amp_h_var), data.(vel_h_var), 'Horizontal')
end

subplot(2,1,2)
if ismember(amp_v_var, data.Properties.VariableNames) && ismember(vel_v_var, data.Properties.VariableNames)
	do_main_seq(data.(amp_v_var), data.(vel_v_var), 'Vertical')
end


% ----------------------------------
function do_main_seq(x, y, title_str)
plot(x, y, '.')
title(title_str)
ylabel('Peak Velocity (°/s)')
xlabel('Amplitude (°)')
return