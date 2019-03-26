
function data = read_apdm_data_test(varargin)
if nargin > 0
    filename = varargin{1};
else
    [fname, pathname] = uigetfile('*.h5', 'select apdm sensor data file');
    filename = fullfile(pathname, fname);
end
% filename = 'sensor_data-20170308-143249.h5';
data = get_apdm_data(filename);

sensor_num = 1;	 % 1=HEAD, 2=right, 3 = left
figure('position',[ 680   118   650   980])
subplot(3,1,1)

plot(data.time, data.accel{sensor_num}(1,:),data.time, data.accel{sensor_num}(2,:),data.time, data.accel{sensor_num}(3,:))
title('accelerometer in sensor ref frame')

subplot(3,1,2)
plot(data.time, data.gyro{sensor_num}(1,:),data.time, data.gyro{sensor_num}(2,:),data.time, data.gyro{sensor_num}(3,:))
title('gyroscope in sensor ref frame')

subplot(3,1,3)
plot(data.time, data.mag{sensor_num}(1,:),data.time, data.mag{sensor_num}(2,:),data.time, data.mag{sensor_num}(3,:))
title('magnetometer in sensor ref frame')

for mm = 1:size(data.mag{sensor_num},2)
   norm_mag(mm) = norm(data.mag{sensor_num}(:,mm));
end

% figure
% plot(data.time,norm_mag)
% title('Magnitude of Magnetometer')
% ylabel( '\muT')
% xlabel('Time (s)')

	
figure
for sensor_num = 1:3
	
	gyro = data.gyro{sensor_num};
	orient = data.orient{sensor_num};
	% angVelEarth = quatrotate(orient',gyro');
	
	% accel = (lpf(data.accel{sensor_num}, 4, 10, 128))';
	% figure
	% plot(data.time, data.accel{sensor_num}(1,:),data.time, data.accel{sensor_num}(2,:),data.time, data.accel{sensor_num}(3,:))
	% hold on
	% plot(data.time, accel(1,:),data.time, accel(2,:),data.time, accel(3,:))
	% title ('accel raw & filtered data')
	% accelEarth = quatrotate(orient', accel');
	
	% figure
	% subplot(2,1,1)
	% plot(data.time,accelEarth(:,1),data.time,accelEarth(:,2),data.time,accelEarth(:,3))
	% title('accel in earth coords using quatrotate')
	
	
	% qr = data.orient{sensor_num}(1,1);
	% qi = data.orient{sensor_num}(2,1);
	% qj = data.orient{sensor_num}(3,1);
	% qk = data.orient{sensor_num}(4,1);
	%
	% % rotation matrix from q
	% R = [1-2*qj^2-2*qk^2, 2*(qi*qj - qk*qr), 2*(qi*qk+qj*qr); ...
	%    2*(qi*qj+qk*qr), 1-2*qi^2-2*qk^2, 2*(qj*qk-qi*qr); ...
	%    2*(qi*qk-qj*qr), 2*(qj*qk+qi*qr), 1-2*qi^2-2*qj^2 ];
	%
	% p = [0; 0; 1]
	% p_rot = R * p
	
	% R rotation agrees with apdm's RotateVector. quatrotate from Matlab's
	% Aerospace toolbox is slightly different
	gyroEarth = apdm_RotateVector(gyro', orient');
	
	% figure
	% plot(data.time, gyroEarth(:,1),data.time, gyroEarth(:,2),data.time, gyroEarth(:,3))
	% title('gyro in earth ref frame')
	
	
	% accelEarth2 = apdm_RotateVector(accel', orient');
	

	subplot(3,3,sensor_num)
	% plot(data.time,accelEarth2(:,1),data.time,accelEarth2(:,2),data.time,accelEarth2(:,3))
	% title('accel in earth coords using RotateVector')
	
	% y vector
	y_vec = [0 1 0];
	y_mat = repmat(y_vec, length(orient),1);
	y_in_earth_ref = apdm_RotateVector(y_mat, orient');
	
	plot(data.time,y_in_earth_ref(:,1),data.time,y_in_earth_ref(:,2),data.time,y_in_earth_ref(:,3))
	title([data.sensor{sensor_num} ' sensor y-axis in earth ref'])
	ylabel('Unit vector component')
	legend('X', 'Y', 'Z')
	
	% angle of unit vector in ref X-Y plane (horizontal)
	head_horiz_angle = atan2d(y_in_earth_ref(:,1), y_in_earth_ref(:,2));
	subplot(3,3,sensor_num+3)
	plot(data.time,head_horiz_angle)
	ylabel('angle (deg)')
	title([data.sensor{sensor_num} ' horizontal angle in earth ref'])
	% xlabel('time (s)')
	
	
	% z vector
	z_vec = [0 0 1];
	z_mat = repmat(z_vec, length(orient), 1);
	z_in_earth_ref = apdm_RotateVector(z_mat, orient');
	% angle of z unit vector
	x_off_vertical_angle = atan2d(z_in_earth_ref(:,1), z_in_earth_ref(:,3));
	subplot(3,3,sensor_num+6)
	plot(data.time,x_off_vertical_angle)
	ylabel('angle (deg)')
	title([data.sensor{sensor_num} ' vertical angle in earth ref'])
	xlabel('time (s)')
	
end % sensor_num
mtit(filename)

% % euler angles
% q = quaternion(orient);
% angles = EulerAngles(q,'123');
% angles = reshape(angles,[3,length(angles)]);
% horiz_angle = angles(3,:);
% if any(horiz_angle>pi*0.9) && any(horiz_angle<-pi*0.9)
% 	horiz_angle(horiz_angle<0) = horiz_angle(horiz_angle<0)+2*pi; % remove discontinuity at +/- pi
% 	horiz_angle = horiz_angle - pi;
% end
% 
% subplot(2,1,2)
% plot(data.time,angles(1,:)*180/pi, data.time,angles(2,:)*180/pi ,data.time,horiz_angle*180/pi)
% ylabel('Euler angles (deg)')
% legend('alpha', 'beta', 'gamma')


% 
% % subtract gravity
% gravity_estimate = mean(accelEarth2(data.time<2,3));
% accel_no_g = accelEarth2;
% accel_no_g(:,3) = accel_no_g(:,3) - gravity_estimate;
% for aa = 1:size(accel_no_g,1)
%    norm_accel_no_g(aa) = norm(accel_no_g(aa,:));
% end
% 
% 
% samp_freq = 1/mean(diff(data.time));
% % velocity - integrate
% vel = cumsum(accel_no_g,1)/samp_freq;
% % position - integrate
% pos = cumsum(vel, 1)/samp_freq;
% 
% figure('position',[ 680   118   650   980])
% subplot(3,1,1)
% plot(data.time, accel_no_g(:,1),data.time, accel_no_g(:,2), data.time, accel_no_g(:,3))
% hold on
% plot(data.time,norm_accel_no_g, 'linewidth',3)
% title('accelerometer minus gravity  earth ref frame')
% 
% 
% subplot(3,1,2)
% plot(data.time, vel(:,1),data.time, vel(:,2), data.time, vel(:,3))
% title('velocity = integral of accel - earth ref frame')
% hold on
% for vv = 1:size(vel,1)
%    norm_vel(vv) = norm(vel(vv));
% end
% subplot(3,1,3)
% plot(data.time, norm_vel, 'linewidth',3)
% title('Magnitude of velocity (m/s)')
% % plot(data.time, pos(:,1),data.time, pos(:,2), data.time, pos(:,3))
% % title('position = integral of velocity - earth ref frame')
% 
% initial = zeros(3,3);
% %output = find_position([data.time, accel', gyro'*pi/180], initial);
