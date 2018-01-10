function mag_orient_test(varargin)


if nargin > 0
    filename = varargin{1};
else
    [fname, pathname] = uigetfile('*.h5', 'select apdm sensor data file');
    filename = fullfile(pathname, fname);
end

data = get_apdm_data(filename);

for mm = 1:size(data.mag{1},2)
   norm_mag(mm) = norm(data.mag{1}(:,mm));
end

figure
subplot(3,1,1)
plot(data.time, data.mag{1}(1,:),data.time, data.mag{1}(2,:),data.time, data.mag{1}(3,:)) %,data.time, norm_mag')
title('magnetometer in sensor ref frame')
legend('x', 'y', 'z', 'norm')


mag_rel_earth = RotateVector(data.mag{1}', data.orient{1}');
for mm = 1:size(mag_rel_earth,1)
   norm_mag(mm) = norm(mag_rel_earth(mm,:));
end
subplot(3,1,2)
plot(data.time, mag_rel_earth(:,1),data.time, mag_rel_earth(:,2),data.time, mag_rel_earth(:,3)) %,data.time,norm_mag)
title('magnetometer in earth ref frame')




for aa = 1:size(mag_rel_earth,1)
   norm_mag_rel_earth(aa) = norm(mag_rel_earth(aa,:));
end

subplot(3,1,3)
plot(data.time, norm_mag_rel_earth)
title('Magnitude')

figure
l_r_angle = atan2(mag_rel_earth(:,2), mag_rel_earth(:,1)) * 180 / pi;
% l_r_angle = atan2(data.mag{1}(2,:), data.mag{1}(1,:)) * 180 / pi;
plot(data.time, l_r_angle)
title('L-R angle')