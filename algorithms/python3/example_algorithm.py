import os
import sys
import json

def preprocess(raw_input, output_file_path, parameters):
    # This is the place to massage the raw_input 
    # It comes in as a width x height x 3 array from calling io.imread
    # If this is not the format you need for your algorithm before it goes into main, you need to massage it manually here.
    return raw_input

def main(input, parameters):
    # This is how you call into functions contained in the example_algorithm folder
    sys.path.insert(0, './example_algorithm')
    algorithm_module = __import__('example_function_module')
    function_handler = getattr(algorithm_module, 'example_function')
    results = function_handler(input)
    return results

def postprocess(main_output, output_file_path):
    import numpy as np
    import json

    # Perform any transformations on the raw output of your algorithm here called in main
    output = main_output

    # Be sure to format your output in JSON format for arrays, etc.
    output = json.dumps(output.tolist())

    # Write the transformed output the output file path. 
    # Generally you shouldn't be touching these lines of code
    with open(output_file_path, 'w') as outfile:
        outfile.write(output)
    
    return True