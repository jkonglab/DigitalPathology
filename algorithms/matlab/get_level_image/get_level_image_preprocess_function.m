function run_folder = get_level_image_preprocess_function(input, output_file_name, inputarr, x_point, y_point, width, height)
    split = strsplit(output_file_name, 'output.json');
    run_folder = split{1};
end