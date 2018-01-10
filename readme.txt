organize data:
	- group trials of data for a recording session in a folder. Name with subject and date and any other relevent info (e.g. subj01_20170901_session1)
	- put each trial in a subfolder 
		- each trial subfolder needs the .edf, .h5, .ett, and overlay0.avi

convert edf2bin:
	- in matlab, cd (change directory) to the subfolder. Can also drag the folder from the finder into the matlab command window.
	- run edf2bin
		>> edf2bin

zero head angle (calibration):
	- run head_cal_gui
		>> head_cal_gui
		- select the .bin file
		- select the .h5 file
		- select the overlay0.avi
	- move blue line to view video at specific times
	- move black horizontal line to the angle to use for head at center
	- move green line to the angle for head to the right
	- move red line to the angle for head to the left 
	- click Export button
	- save the file "head_cal.mat" to the folder containing all the trials

view and select data
	- run hand_eye_gui
		>> hand_eye_gui
		- select the .bin file
		- select the .h5 file
		- select the overlay0.avi
	- if there is an error about the adjust bias file, edit the adjust bias file removing '_1' from the .bin file near the top
	- right-click = control-click 
	- right-click on lines and axes to view menus of options
	- magenta line = gyroscope corrected velocity line. Acceleration was integrated to compute velocity. Then when the gyroscope was below threshold (i.e. there was no movement detected) the velocity is reset to zero.
	- green line in the head plot is the head left-right angle
	- move blue line to view video at specific times
	- can zoom in on any plot. All plots will show the same timespan
	- To move the blue line into view, enter the time int he upper right time = field.
	- Left group of LH,RH,LV,RV buttons are to show and hide fixations.
	- Right group of LH,RH,LV,RV buttons are to show and hide saccades.
	- For saccade or fixation info to be saved to the export file, the corresponding button must be clicked at least once. The first time a saccade or fixation button is clicked, the data is read in. Subsequent clicks just toggle the visibility of the data on the plot. If the button has never been clicked, then that saccade or fixation info is not sent to the exported file.
	- Right-click on a saccade to disable it. It will turn into an x.
	- Identify Moves by right-clicking on the magenta line (near the center of the move area). Reach type determines if the identified move should have 1 or 3 humps. Adjust the start, stop, and intermediate points by dragging them.
	- Exclude data or identify specific data to analyze by right-clicking on the Gaze pos axis. To move the patch, right-click to unlock it, then drag the edges of the patch.	
