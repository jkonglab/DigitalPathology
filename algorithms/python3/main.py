import os
import sys
import math
from skimage import io
import openslide
from openslide import open_slide

def main(argv):
    file_folder_path = argv[0] 
    image_name = argv[1]
    output_file_path = argv[2] 
    algorithm_name = argv[3] 
    tile_x = int(argv[4])
    tile_y = int(argv[5])
    tile_width = int(argv[6])
    tile_height = int(argv[7])
    roi_type = int(argv[8])
    parameters = argv[9:]

    if roi_type == "dzi":
        roi = get_roi_dzi(tile_x, tile_y, tile_width, tile_height, file_folder_path)
    else:
        roi = get_roi_wholeslide(tile_x, tile_y, tile_width, tile_height, file_folder_path, image_name)

    # Set up function handlers to call correct algorithm
    algorithm_module = __import__(algorithm_name)
    preprocessing_function_handler = getattr(algorithm_module, 'preprocess')
    main_function_handler = getattr(algorithm_module, 'main')
    postprocessing_function_handler = getattr(algorithm_module, 'postprocess')

    main_input = preprocessing_function_handler(roi, output_file_path, parameters)
    main_output = main_function_handler(main_input, parameters)
    postprocessing_function_handler(main_output, output_file_path)

def get_dzi_file(tile_folder_path, dzi_x_index, dzi_y_index):
    items = os.listdir(tile_folder_path)
    folder_numbers = list(map(graceful_str2int, items))
    maximum = max(folder_numbers);
    image_file = tile_folder_path + '/' + str(maximum) + '/' + str(dzi_x_index) + '_' + str(dzi_y_index) + '.png'
    return image_file

def get_roi_dzi(tile_x, tile_y, tile_width, tile_height, tile_folder_path):
    # Get the roi region to be analyzed
    dzi_size = 2048
    dzi_x_index = int(math.floor(tile_x / dzi_size))
    dzi_y_index = int(math.floor(tile_y / dzi_size))
    x_offset = tile_x%dzi_size
    y_offset = tile_y%dzi_size
    image_file = get_dzi_file(tile_folder_path, dzi_x_index, dzi_y_index)
    image = io.imread(image_file)
    roi = image[y_offset:y_offset+tile_height,x_offset:x_offset+tile_width]
    return roi

def get_roi_wholeslide(tile_x, tile_y, tile_width, tile_height, image_folder_path, image_name):
    slide = open_slide(os.path.join(image_folder_path, image_name))
    roi = slide.read_region((tile_x,tile_y), 0, (tile_width, tile_height)) #annotation coordinates and size
    return roi

def graceful_str2int(string):
    try:
        return int(string)
    except ValueError:
        return 0

if __name__ == "__main__":
    main(sys.argv[1:])