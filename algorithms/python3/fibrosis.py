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

def preprocess(raw_input, output_file_path, parameters):
	return raw_input

def postprocess(main_output, output_file_path):
	import numpy as np
	import json

	output = json.dumps(np.asarray(main_output).T.tolist())

	with open(output_file_path, 'w') as outfile:
  		outfile.write(output)
	return True

def main(input, parameters):
	sys.path.insert(0, './fibrosis')
	algorithm_module = __import__('predict')
	function_handler = getattr(algorithm_module, 'predict_return')
	results = function_handler(input)
	return results