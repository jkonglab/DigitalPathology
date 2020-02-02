from cv2 import cv2
import os
import sys
import numpy as np

def preprocess(raw_input, output_file_path, parameters):
    return raw_input

def postprocess(main_output, output_file_path):
    cv2.imwrite(os.path.join(output_file_path, 'output_roi.png'), main_output)

def main(img, params):
    copy_img = img.copy()
    return copy_img

