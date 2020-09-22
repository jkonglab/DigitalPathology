function result = get_level_image_postprocess_function(input, output_file_name)
    result = input;
    dlmwrite(output_file_name,jsonencode(result),'');
end
