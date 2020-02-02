from time import time, localtime
import os
import sys

def preprocess(raw_input, output_file_path, parameters):
    return raw_input


def postprocess(main_output, output_file_path):
    sys.path.insert(0, './color_deconv_utils')
    algorithm_module = __import__('color_deconv_utils')
    function_handler = getattr(algorithm_module,'save_im')
    img, mask = main_output
    function_handler(os.path.join(output_file_path, 'output_white_pixel_mask.png'), mask)
    function_handler(os.path.join(output_file_path, 'output_input_tile.png'), img)


def main(img, params):
    ref = None
    sys.path.insert(0, './color_deconv_utils')
    algorithm_module = __import__('color_deconv_utils')
    function_handler = getattr(algorithm_module,'hsv_get_white')
    mask = function_handler(img)
    return img, mask











