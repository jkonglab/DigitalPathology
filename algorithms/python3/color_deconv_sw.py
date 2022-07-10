from time import time, localtime
import os
import sys
import numpy as np
import cv2
from PIL import Image

def preprocess(raw_input, output_file_path, parameters):
    img = raw_input.convert('RGB')
    img = np.array(img)
    return img


def postprocess(main_output, output_file_path):
    sys.path.insert(0, './color_deconv_utils')
    algorithm_module = __import__('color_deconv_utils')
    function_handler = getattr(algorithm_module,'save_im')
    img, mask = main_output
    function_handler(os.path.join(output_file_path, 'output_white_pixel_mask.tif'), mask)
    function_handler(os.path.join(output_file_path, 'output_input_tile.tif'), img)
    f = open(os.path.join(output_file_path, 'output.json'), 'w')
    f.close()

def main(img, params):
    ref = None
    sys.path.insert(0, './color_deconv_utils')
    algorithm_module = __import__('color_deconv_utils')
    function_handler = getattr(algorithm_module,'hsv_get_white')
    mask = function_handler(img)
    return img, mask











