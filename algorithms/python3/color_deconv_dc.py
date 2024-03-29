import sys
from time import time, localtime
import os
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
    img, H, E = main_output
    function_handler(os.path.join(output_file_path, 'output_H.tif'), H)
    function_handler(os.path.join(output_file_path, 'output_E.tif'), E)
    function_handler(os.path.join(output_file_path, 'output_input_tile.tif'), img)
    f = open(os.path.join(output_file_path, 'output.json'), 'w')
    f.close()

def main(img, params):
    ref = None
    rf_img = None
    sys.path.insert(0, './color_deconv_utils')
    algorithm_module = __import__('color_deconv_utils')

    if params[0] == 'HE':
        function_handler = getattr(algorithm_module,'Ref')
        ref = function_handler.get_he_ref()
    elif params[0] == 'IHC':
        function_handler = getattr(algorithm_module,'Ref')
        ref = function_handler.get_ihc_ref()
    elif params[0] == 'Customer':
        # reference image
        try:
            function_handler = getattr(algorithm_module,'read_im')
            img_file = "/mnt/dpdata/share/imageviewer/upload_data/"+params[1]
            rf_img = function_handler(img_file)
        except TypeError:
            print("The option `--ref_img` is necessary when choose `Customer` as the option `--ref`.")
        function_handler = getattr(algorithm_module,'custom_ref')
        ref = function_handler(rf_img)
    elif params[0] == 'None': 
        function_handler = getattr(algorithm_module,'Ref')
        ref =  None

    function_handler = getattr(algorithm_module, 'stain_deconv')
    H, E = function_handler(img, ref)
    return img, H, E
