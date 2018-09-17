import numpy as np
import theano
import theano.tensor as T
import pickle
import lasagne
import scipy.ndimage.filters as filters
import matplotlib.pyplot as plt
import skimage.data
import os
import sys
import json
import cv2

def preprocess(raw_input, output_file_path, parameters):
	converted = cv2.cvtColor(np.array(raw_input), cv2.COLOR_BGR2RGB)
	return converted.T

def postprocess(main_output, output_file_path):
	import numpy as np
	import json

	for i in range(len(main_output)):
		main_output[i] = [main_output[i]]

	output = json.dumps(main_output)

	with open(output_file_path, 'w') as outfile:
		outfile.write(output)
	return True

def main(input, parameters):
	sys.path.insert(0, './fibrosis')
	algorithm_module = __import__('predict')
	function_handler = getattr(algorithm_module, 'predict_return')
	results = function_handler(input)
	return results