function magnetometer_angle(mag_data)



for mm = 1:size(mag_data,2)
   norm_mag(mm) = norm(mag_data(:,mm));
end

figure
subplot(3,1,1)
plot(data.time, data.mag{1}(1,:),data.time, data.mag{1}(2,:),data.time, data.mag{1}(3,:)) %,data.time, norm_mag')
title('magnetometer in sensor ref frame')
legend('x', 'y', 'z', 'norm')


mag_rel_earth = RotateVector(mag_data', data.orient{1}');
for mm = 1:size(mag_rel_earth,1)
   norm_mag(mm) = norm(mag_rel_earth(mm,:));
end
subplot(3,1,2)
plot(data.time, mag_rel_earth(:,1),data.time, mag_rel_earth(:,2),data.time, mag_rel_earth(:,3)) %,data.time,norm_mag)
title('magnetometer in earth ref frame')


l_r_angle = atan2(mag_rel_earth(:,2), mag_rel_earth(:,1)) * 180 / pi;

subplot(3,1,3)
plot(data.time, l_r_angle)
title('L-R Angle')