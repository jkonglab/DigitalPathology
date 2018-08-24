"""
Mask R-CNN
Train on the nuclei segmentation dataset from the
Kaggle 2018 Data Science Bowl
https://www.kaggle.com/c/data-science-bowl-2018/

Licensed under the MIT License (see LICENSE for details)
Written by Waleed Abdulla

------------------------------------------------------------

Usage: import the module (see Jupyter notebooks for examples), or run from
       the command line as such:

    # Train a new model starting from ImageNet weights
    python3 steatosis.py train --dataset=/path/to/dataset --subset=train --weights=imagenet

    # Train a new model starting from specific weights file
    python3 steatosis.py train --dataset=/path/to/dataset --subset=train --weights=/path/to/weights.h5

    # Resume training a model that you had trained earlier
    python3 steatosis.py train --dataset=/path/to/dataset --subset=train --weights=last

    # Generate submission file
    python3 steatosis.py detect --dataset=/path/to/dataset --subset=train --weights=<last or /path/to/weights.h5>
"""

# Set matplotlib backend
# This has to be done before other importa that might
# set it, but only if we're running in script mode
# rather than being imported.

import os
import sys
import numpy as np
import cv2
import colorsys 
import matplotlib
from skimage import measure

from steatosis2_Predict import random_colors

def filer(min_score, max_score,r,image):
    #pred_DIR = os.path.join(DATASET_DIR, "prediction_results/") 
    #directory = os.path.dirname(pred_DIR)
    #if not os.path.exists(directory):
    #    os.makedirs(directory)
    #image = cv2.imread(DATASET_DIR+"/"+image_name,1)  
    #print(type(image))
    result = r
    scores = result['scores']
    masks = result['masks']
    order = np.argsort(scores)[::-1] + 1  # 1-based descending
    masks = np.max(masks * np.reshape(order, [1, 1, -1]), -1)
    alpha = 0.7
    inx = -1
    invalid = 0
    N = len(result['class_ids'])
    #print("class id N is {}".format(N))
    colors = random_colors(N)
    image = np.array(image)
    image_masked = image
    #print("image shape is {}".format(image.shape))
    contours = []
    for c_id in result['class_ids']:
        inx = inx + 1
        #score = result['scores'][inx]
        pred_mask = result['masks'][:, :, inx]
        pred_mask = np.array(pred_mask, dtype=np.uint8)   
        temp,contour,hierarchy=cv2.findContours(pred_mask,1,2)
        area=cv2.contourArea(contour[0])
        if len(contour[0])<6:
            continue
        #ellipse = cv2.fitEllipse(contour[0])
        #perimeter = cv2.arcLength(contour[0],True)
        #print("ellipse is {}".format(ellipse))
        contours.append(contour[0])        
    return np.array(contours)
    print("Finished!\n")

def compute_features(mask_array):
    from skimage.measure import label, regionprops
    label_img = label(image)
    regions = regionprops(label_img)



   
