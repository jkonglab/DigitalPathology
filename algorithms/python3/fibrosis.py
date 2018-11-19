import numpy as np
import os
import sys
import json
import cv2

def preprocess(raw_input, output_file_path, parameters):
    print("convert")
    rgb = raw_input[:,:,:3]
    bgr = rgb[...,::-1]
    if bgr.shape[0] < 256 or bgr.shape[1] < 256:
        zeros = np.zeros((256,256,3), dtype=int)
        zeros[:bgr.shape[0],:bgr.shape[1],:] = bgr
        output = zeros
    else:
        output = bgr
    return output.T



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