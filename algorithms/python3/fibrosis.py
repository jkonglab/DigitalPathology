import numpy as np
import os
import sys
import json
import cv2

def preprocess(raw_input, output_file_path, parameters):
    print("convert")
    rgb = raw_input[:,:,:3]
    #bgr = rgb[...,::-1]
    img = rgb 
    img = img.astype(np.float32)
    img[:,:,0] -= 103.939
    img[:,:,1] -= 116.779
    img[:,:,2] -= 123.68
    if img.shape[0] < 256 or img.shape[1] < 256:
        zeros = np.zeros((256,256,3), dtype=int)
        zeros[:img.shape[0],:img.shape[1],:] = img
        output = zeros
    else:
        output = img
    #return output.T
    return np.rollaxis(output, 2, 0)



def postprocess(main_output, output_file_path):
    import numpy as np
    import json

    # comment the two lines to make sure the format of the output contours coordinates are correct
    #for i in range(len(main_output)):
    #    main_output[i] = [main_output[i]]

    contours, target_pixel_number = main_output
    output = json.dumps(contours)

    with open(output_file_path, 'w') as outfile:
        outfile.write(output)
    return True

def main(input, parameters):
    sys.path.insert(0, './fibrosis')
    algorithm_module = __import__('predict')
    function_handler = getattr(algorithm_module, 'predict_return')
    results = function_handler(input)
    return results
