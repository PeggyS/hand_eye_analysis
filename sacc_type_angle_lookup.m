function sacc_type = sacc_type_angle_lookup(sacc_angle)

if sacc_angle >= -45 && sacc_angle <= 45
	sacc_type = {'Progressive'};
elseif sacc_angle <= -135 || sacc_angle >= 135
	sacc_type = {'Regressive'};
else
	sacc_type = {'Irrelevant'};
end