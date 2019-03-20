
function data = apdm_detect_reaches(varargin)
% optional input parameter = h5 file name (string)


if nargin > 0,
    filename = varargin{1};
else
    [fname, pathname] = uigetfile('*.h5', 'select apdm sensor data file');
    filename = fullfile(pathname, fname);
end
data = get_apdm_data(filename);

% plot raw (calibrated_ data
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

% % magnitude of magnetometer data
% for mm = 1:size(data.mag{1},2)
%    norm_mag(mm) = norm(data.mag{1}(:,mm));
% end
% 
% figure
% plot(data.time,norm_mag)
% title('Magnitude of Magnetometer')
% ylabel( '\muT')
% xlabel('Time (s)')


gyro = data.gyro{1};
orient = data.orient{1};
% angVelEarth = quatrotate(orient',gyro');

% low pass filter accel data
%accel = (lpf(data.accel{1}, 4, 6, 128))';
accel = data.accel{1};
% figure
% plot(data.time, data.accel{1}(1,:),data.time, data.accel{1}(2,:),data.time, data.accel{1}(3,:))
% hold on
% plot(data.time, accel(1,:),data.time, accel(2,:),data.time, accel(3,:))
% title ('accel raw & filtered data')

% accel & gyro in earth ref frame
gyroEarth = apdm_RotateVector(gyro', orient');
% filter gyro data
% gyroEarth = lpf(gyroEarth, 4, 1, 128);
for gg = 1:size(gyroEarth,1),
   norm_gyroEarth(gg) = norm(gyroEarth(gg,:));
end


accelEarth = apdm_RotateVector(accel', orient');


figure
plot(data.time, gyroEarth(:,1),data.time, gyroEarth(:,2),data.time, gyroEarth(:,3))
hold on 
plot(data.time, accel(1,:),data.time, accel(2,:),data.time, accel(3,:))

% plot(data.time,norm_gyroEarth, 'linewidth', 3)
title('gyro & accel in earth ref frame')

% subtract gravity
gravity_estimate = mean(accelEarth(data.time<2,3));
accel_no_g = accelEarth;
accel_no_g(:,3) = accel_no_g(:,3) - gravity_estimate;
for aa = 1:size(accel_no_g,1)
   norm_accel_no_g(aa) = norm(accel_no_g(aa,:));
end


samp_freq = 1/mean(diff(data.time));
% velocity - integrate
vel = cumsum(accel_no_g,1)/samp_freq;
% position - integrate
pos = cumsum(vel, 1)/samp_freq;

% when gyro magnitude is < threshold, call that zero velocity -> reset integrated
% velocity to 0
gyro_corrected_vel = zeros(size(vel));
ind = 1;
threshold = 0.1;
while ind <= length(norm_gyroEarth),
   if norm_gyroEarth(ind) < threshold, % zero vel, look for end of zero vel segment
      next_ind = find(norm_gyroEarth(ind:end) > threshold, 1) + ind - 1; % index of 1st non-zero velocity
      if isempty(next_ind),
         break
      end
      
      ind = next_ind;
   else
      % in non-zero segment, look for its end
      next_ind = find(norm_gyroEarth(ind:end) < threshold, 1) + ind - 1; % index of end of non-zero segment
      if isempty(next_ind),
         break
      end
      % during this non-zero segment, compute the integral of accel
      gyro_corrected_vel(ind:next_ind,:) = cumsum(accel_no_g(ind:next_ind,:),1)/samp_freq;
      ind = next_ind;
   end
end

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
plot(data.time, gyro_corrected_vel(:,1),data.time, gyro_corrected_vel(:,2), data.time, gyro_corrected_vel(:,3))
title('gyro corrected velocity  - earth ref frame')

