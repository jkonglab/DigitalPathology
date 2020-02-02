import sys
from time import time, localtime
import os


def preprocess(raw_input, output_file_path, parameters):
    return raw_input


def postprocess(main_output, output_file_path):
    sys.path.insert(0, './color_deconv_utils')
    algorithm_module = __import__('color_deconv_utils')
    function_handler = getattr(algorithm_module,'save_im')
    img, Inorm = main_output
    function_handler(os.path.join(output_file_path, 'output_norm.png'), Inorm)
    function_handler(os.path.join(output_file_path, 'output_input_tile.png'), img)


def main(img, params):
    ref = None
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
            img_file = "/DP_Share/imageviewer/public/uploads/"+params[1]
            rf_img = function_handler(img_file)
        except TypeError:
            print("The option `--ref_img` is necessary when choose `Customer` as the option `--ref`.")
        function_handler = getattr(algorithm_module,'custom_ref')
        ref = function_handler(rf_img)
    elif params[0] == 'None':
        function_handler = getattr(algorithm_module,'Ref')
        ref =  None

    function_handler = getattr(algorithm_module,'stain_norm')
    Inorm = function_handler(img, ref)
    return img, Inorm