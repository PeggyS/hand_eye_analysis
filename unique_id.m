function new_id = unique_id(old_id_list)

% old_id_list = vector of unique numbers
max_val = max(old_id_list);
if ~isempty(max_val)
	new_id =  max_val + 1;
else
	new_id = 1;
end

return