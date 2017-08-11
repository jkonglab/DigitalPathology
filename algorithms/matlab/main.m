function result = main(svs_file_path, extra_parameters_array, algorithm_name, tile_x, tile_y, tile_size)
   addpath('.')
   Rows = [tile_x, tile_x + tile_size]
   Cols = [tile_y, tile_y + tile_size]
   roi = imread(svs_file_path,'Index',index,'PixelRegion',{Rows,Cols});
   extra_parameters_cell_array = num2cell(extra_parameters_array)

   preprocessing_function_handler = str2func(strcat(algorithm_name, '_preprocess_function'))
   main_function_handler = str2func(strcat(algorithm_name, '_main_function'))
   postprocessing_function_handler = str2func(strcat(algorithm_name, '_postprocess_function'))
   
   main_input = preprocessing_function_handler(roi);
   main_output = main_function_handler(main_input, extra_parameters_cell_array{:})
   postprocessing_function_handler(main_output)
end
