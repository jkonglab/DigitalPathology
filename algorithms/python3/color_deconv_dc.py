import sys
from time import time, localtime
import os


def preprocess(raw_input, output_file_path, parameters):
	return raw_input


def postprocess(main_output, output_file_path):
	sys.path.insert(0, './color_deconv_utils')
	algorithm_module = __import__('color_deconv_utils')
	function_handler = getattr(algorithm_module,'save_im')
	H, E = main_output
	function_handler(os.path.join(output_file_path, 'output_H.png'), H)
	function_handler(os.path.join(output_file_path, 'output_E.png'), E)


def main(img, params):
	ref = None
	sys.path.insert(0, './color_deconv_utils')
	algorithm_module = __import__('color_deconv_utils')
	if params[0] == 'HE':
		function_handler = getattr(algorithm_module,'Ref.get_he_ref')
		ref = function_handler()
	elif params[0] == 'Customer':
		# reference image
		try:
			function_handler = getattr(algorithm_module,'read_im')
			rf_img = function_handler(params[2])
		except TypeError:
			print("The option `--ref_img` is necessary when choose `Customer` as the option `--ref`.")
		function_handler = getattr(algorithm_module,'custom_ref')
		ref = function_handler(rf_img)
	elif params[0] == 'None':
		ref = None

	function_handler = getattr(algorithm_module, 'stain_deconv')
	H, E = function_handler(img, ref)
	return H, E










