function out_data = apply_vergence_cal(in_data, cal_info)

out_data = in_data + cal_info.data_offset;
out_data(out_data > cal_info.offset_angle) = out_data(out_data > cal_info.offset_angle) * cal_info.scale_factor(1);
out_data(out_data < cal_info.offset_angle) = out_data(out_data < cal_info.offset_angle) * cal_info.scale_factor(2);
% cal_info.scale_angle = [10 -10];
% cal_info.scale_factor = [2 3];

