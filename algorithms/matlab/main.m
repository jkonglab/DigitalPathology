function result = main(svs_file_path, extra_parameters_array, algorithm_name)


   addpath('.')
   svs_file = imread(svs_file_path,'Index',1);
   extra_parameters_cell_array = num2cell(extra_parameters_array)
   preprocessing_function_handler = str2func(strcat(algorithm_name, '_preprocess_function'))
   main_function_handler = str2func(strcat(algorithm_name, '_main_function'))
   postprocessing_function_handler = str2func(strcat(algorithm_name, '_postprocess_function'))
   
   main_input = preprocessing_function_handler(svs_file)
   main_output = main_function_handler(main_input, extra_parameters_cell_array{:})
   postprocessing_function_handler(main_output)

end
