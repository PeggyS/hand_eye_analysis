
function data = read_apdm_data_test(varargin)

if nargin > 0,
    filename = varargin{1};
else
    [fname, pathname] = uigetfile('*.h5', 'select apdm sensor data file');
    filename = fullfile(pathname, fname);
end
% filename = 'sensor_data-20170308-143249.h5';
data = get_apdm_data(filename);


figure('position',[ 680   118   650   980])
subplot(3,1,1)

plot(data.time, data.accel{1}(1,:),data.time, data.accel{1}(2,:),data.time, data.accel{1}(3,:))
title('accelerometer in sensor ref frame')

subplot(3,1,2)
plot(data.time, data.gyro{1}(1,:),data.time, data.gyro{1}(2,:),data.time, data.gyro{1}(3,:))
title('gyroscope in sensor ref frame')

subplot(3,1,3)
plot(data.time, data.mag{1}(1,:),data.time, data.mag{1}(2,:),data.time, data.mag{1}(3,:))
title('magnetometer in sensor ref frame')

for mm = 1:size(data.mag{1},2)
   norm_mag(mm) = norm(data.mag{1}(:,mm));
end

figure
plot(data.time,norm_mag)
title('Magnitude of Magnetometer')
ylabel( '\muT')
xlabel('Time (s)')

% gyro = h5read('foo.h5', '/SI-000111/Calibrated/Gyroscopes')';
% orientation = h5read('foo.h5', '/SI-000111/Calibrated/Orientation')';
% angularVelocityEarth = RotateVector(gyro, orientation);

gyro = data.gyro{1};
orient = data.orient{1};
% angVelEarth = quatrotate(orient',gyro');

accel = (lpf(data.accel{1}, 4, 10, 128))';
figure
plot(data.time, data.accel{1}(1,:),data.time, data.accel{1}(2,:),data.time, data.accel{1}(3,:))
hold on
plot(data.time, accel(1,:),data.time, accel(2,:),data.time, accel(3,:))
title ('accel raw & filtered data')
% accelEarth = quatrotate(orient', accel');

% figure
% subplot(2,1,1)
% plot(data.time,accelEarth(:,1),data.time,accelEarth(:,2),data.time,accelEarth(:,3))
% title('accel in earth coords using quatrotate') 


% qr = data.orient{1}(1,1);
% qi = data.orient{1}(2,1);
% qj = data.orient{1}(3,1);
% qk = data.orient{1}(4,1);
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
gyroEarth = RotateVector(gyro', orient');

figure
plot(data.time, gyroEarth(:,1),data.time, gyroEarth(:,2),data.time, gyroEarth(:,3))
title('gyro in earth ref frame')


accelEarth2 = RotateVector(accel', orient');
% subplot(2,1,2)
% figure
% plot(data.time,accelEarth2(:,1),data.time,accelEarth2(:,2),data.time,accelEarth2(:,3))
% title('accel in earth coords using VectorRotate')

% subtract gravity
gravity_estimate = mean(accelEarth2(data.time<2,3));
accel_no_g = accelEarth2;
accel_no_g(:,3) = accel_no_g(:,3) - gravity_estimate;
for aa = 1:size(accel_no_g,1)
   norm_accel_no_g(aa) = norm(accel_no_g(aa,:));
end


samp_freq = 1/mean(diff(data.time));
% velocity - integrate
vel = cumsum(accel_no_g,1)/samp_freq;
% position - integrate
pos = cumsum(vel, 1)/samp_freq;

figure('position',[ 680   118   650   980])
subplot(3,1,1)
plot(data.time, accel_no_g(:,1),data.time, accel_no_g(:,2), data.time, accel_no_g(:,3))
hold on
plot(data.time,norm_accel_no_g, 'linewidth',3)
title('accelerometer minus gravity  earth ref frame')


subplot(3,1,2)
plot(data.time, vel(:,1),data.time, vel(:,2), data.time, vel(:,3))
title('velocity = integral of accel - earth ref frame')
hold on
for vv = 1:size(vel,1)
   norm_vel(vv) = norm(vel(vv));
end
subplot(3,1,3)
plot(data.time, norm_vel, 'linewidth',3)
title('Magnitude of velocity (m/s)')
% plot(data.time, pos(:,1),data.time, pos(:,2), data.time, pos(:,3))
% title('position = integral of velocity - earth ref frame')

initial = zeros(3,3);
%output = find_position([data.time, accel', gyro'*pi/180], initial);
