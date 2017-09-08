function result = main(image_path, run_folder_path, extra_parameters_array, algorithm_name, tile_x, tile_y, tile_size)
   addpath('.')
   Rows = [tile_x, tile_x + tile_size - 1];
   Cols = [tile_y, tile_y + tile_size - 1];
   tiled_roi = imread(image_path,'Index',1,'PixelRegion',{Rows,Cols});
   extra_parameters_cell_array = num2cell(extra_parameters_array);
   output_file_name = strcat(run_folder_path,'/output_',num2str(tile_x),'_',num2str(tile_y),'.json');

   preprocessing_function_handler = str2func(strcat(algorithm_name, '_preprocess_function'));
   main_function_handler = str2func(strcat(algorithm_name, '_main_function'));
   postprocessing_function_handler = str2func(strcat(algorithm_name, '_postprocess_function'));
   
   main_input = preprocessing_function_handler(tiled_roi);
   main_output = main_function_handler(main_input, extra_parameters_cell_array{:});
   postprocessing_function_handler(main_output, output_file_name);
end
