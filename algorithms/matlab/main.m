function result = main(image_path, run_folder_path, extra_parameters_array, algorithm_name, tile_x, tile_y, tile_width, tile_height)
   addpath('.')
   
   if tile_width ~= 0 && tile_height ~= 0
      Rows = [tile_x, tile_x + tile_width - 1];
      Cols = [tile_y, tile_y + tile_height - 1];
      if contains(image_path, '.ndpi') || contains(image_path, '.svs')
        tiled_roi = imread(image_path,'Index',1,'PixelRegion',{Rows,Cols});
      else
        entire_image = imread(image_path);
        tiled_roi = entire_image(tile_x:tile_x + tile_width - 1, tile_y:tile_y + tile_height - 1, :);
      end
   else
      tiled_roi = [];
   end

   output_file_name = strcat(run_folder_path,'/output_',num2str(tile_x),'_',num2str(tile_y),'.json');

   preprocessing_function_handler = str2func(strcat(algorithm_name, '_preprocess_function'));
   main_function_handler = str2func(strcat(algorithm_name, '_main_function'));
   postprocessing_function_handler = str2func(strcat(algorithm_name, '_postprocess_function'));
   
   main_input = preprocessing_function_handler(tiled_roi, output_file_name, extra_parameters_array{:});
   main_output = main_function_handler(main_input, extra_parameters_array{:});
   postprocessing_function_handler(main_output, output_file_name);
end
