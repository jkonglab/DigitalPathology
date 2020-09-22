function run_folder = high_low_registration_preprocess_function(input, output_file_name, inputarr, input_mat_file_path, x_point, y_point, width, height)
    split = strsplit(output_file_name, 'output.json');
    run_folder = split{1};
end