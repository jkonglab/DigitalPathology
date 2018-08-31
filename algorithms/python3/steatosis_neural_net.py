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

    for i in range(main_output.shape[0]):
        main_output[i] = np.squeeze(main_output[i]/2).tolist()

    output = json.dumps(main_output.tolist())

    with open(output_file_path, 'w') as outfile:
        outfile.write(output)
    return True

def main(input, parameters):
    sys.path.insert(0, './steatosis_neural_net')
    algorithm_module = __import__('prediction')
    function_handler = getattr(algorithm_module, 'Predict')
    results = function_handler(input)
    return results

