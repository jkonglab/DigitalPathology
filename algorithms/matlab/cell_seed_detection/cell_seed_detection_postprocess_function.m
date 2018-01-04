function result = cell_seed_detection_postprocess_function(input, output_file_name)
	result = input;
	dlmwrite(output_file_name,jsonencode(result),'');
end
