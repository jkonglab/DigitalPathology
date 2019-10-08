from time import time, localtime
import os


def preprocess(raw_input, output_file_path, parameters):
	return raw_input


def postprocess(main_output, output_file_path):
	sys.path.insert(0, './color_deconv_utils')
	algorithm_module = __import__('color_deconv_utils')
	function_handler = getattr(algorithm_module,'save_im')
	mask, name = main_output
	function_handler(os.path.join(output_file_path, name+'_white_pixel_mask.png'), mask)


def main(img, params):
	sys.path.insert(0, './color_deconv_utils')
	algorithm_module = __import__('color_deconv_utils')
	function_handler = getattr(algorithm_module,'hsv_get_white')
	if params[0] == 'default':
		tc = localtime(time())
		name = '{:04d}{:02d}{:02d}{:02d}{:02d}{:02d}'.format(tc.tm_year, tc.tm_mon, tc.tm_mday, tc.tm_hour, tc.tm_min, tc.tm_sec)
	else:
		name = params[0]
	mask = function_handler(img)
	return mask, name











