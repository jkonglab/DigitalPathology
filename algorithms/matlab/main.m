function main_output = main(image_folder_path, output_file_path, extra_parameters_array, algorithm_name, tile_x, tile_y, tile_width, tile_height)
   addpath('.')
   addpath(['./' algorithm_name]) 
   dzi_size = 2000;
   dzi_x_index = floor(tile_x / dzi_size);
   dzi_y_index = floor(tile_y / dzi_size);
   x_offset =  mod(tile_x, dzi_size);
   y_offset =  mod(tile_y, dzi_size);
   
   items = dir(image_folder_path);
   subfolders = {items([items.isdir]).name};
   folder_numbers = cell2mat(cellfun(@str2num, subfolders(:,1:end), 'un', 0));
   maximum = max(folder_numbers);
   
   image_file = strcat(image_folder_path, '/', num2str(maximum), '/', num2str(dzi_x_index), '_', num2str(dzi_y_index), '.jpeg');

   if tile_width ~= 0 && tile_height ~= 0
      entire_image = imread(image_file);
      image_size = size(entire_image);
      end_height = y_offset + tile_height;
      end_width = x_offset + tile_width;
      if end_height > image_size(1)
          end_height = image_size(1);
      end
      if end_width > image_size(2)
          end_width = image_size(2);
      end
      tiled_roi = entire_image(y_offset+1:end_height, x_offset+1:end_width, :);
   else
      tiled_roi = [];
   end

   preprocessing_function_handler = str2func(strcat(algorithm_name, '_preprocess_function'));
   main_function_handler = str2func(strcat(algorithm_name, '_main_function'));
   postprocessing_function_handler = str2func(strcat(algorithm_name, '_postprocess_function'));
   
   main_input = preprocessing_function_handler(tiled_roi, output_file_path, extra_parameters_array{:});
   main_output = main_function_handler(main_input, extra_parameters_array{:});
   postprocessing_function_handler(main_output, output_file_path);
end
