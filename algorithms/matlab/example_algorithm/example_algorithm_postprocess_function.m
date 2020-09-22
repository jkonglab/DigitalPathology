function result = example_algorithm_postprocess_function(input, output_file_name)
	% Any post processing on result should go in here before you write it to file
	result = input;

	% LEAVE THIS LINE BELOW ALONE
	dlmwrite(output_file_name,jsonencode(result),'');
end
