function run_folder = generate_registered_images_preprocess_function(tiled_roi, output_file_name, inputs)
    split = strsplit(output_file_name, 'output.json');
    run_folder = split{1};
end