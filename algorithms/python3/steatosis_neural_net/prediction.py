import os
import sys
import colorsys
ROOT_DIR = os.path.abspath("../../")
sys.path.append(ROOT_DIR)  # To find local version of the library
LOGS_DIR = os.path.join(ROOT_DIR, "logs")  
import random
import math
import re
import time
import numpy as np
import tensorflow as tf
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from mrcnn import utils
from mrcnn import visualize2
from mrcnn.visualize2 import display_images
import mrcnn.model2 as modellib
from mrcnn.model2 import log
import numpy as np
import cv2
import steatosis2
from Filter_prediction_results import filer


# This code is used for predicting the mask of different steatosis for Project 2_2

def load_image(config,image):
    """Load and return ground truth data for an image (image, mask, bounding boxes).

    augment: (Depricated. Use augmentation instead). If true, apply random
        image augmentation. Currently, only horizontal flipping is offered.
    augmentation: Optional. An imgaug (https://github.com/aleju/imgaug) augmentation.
        For example, passing imgaug.augmenters.Fliplr(0.5) flips images
        right/left 50% of the time.
    use_mini_mask: If False, returns full-size masks that are the same height
        and width as the original image. These can be big, for example
        1024x1024x100 (for 100 instances). Mini masks are smaller, typically,
        224x224 and are generated by extracting the bounding box of the
        object and resizing it to MINI_MASK_SHAPE.

    Returns:
    image: [height, width, 3]
    shape: the original shape of the image before resizing and cropping.
    class_ids: [instance_count] Integer class IDs
    bbox: [instance_count, (y1, x1, y2, x2)]
    mask: [height, width, instance_count]. The height and width are those
        of the image unless use_mini_mask is True, in which case they are
        defined in MINI_MASK_SHAPE.
    """
    image_id =  1
    original_shape = image.shape
    image, window, scale, padding, crop = utils.resize_image(
        image,
        min_dim=config.IMAGE_MIN_DIM,
        min_scale=config.IMAGE_MIN_SCALE,
        max_dim=config.IMAGE_MAX_DIM,
        mode=config.IMAGE_RESIZE_MODE)
  
    image_meta = compose_image_meta(image_id, original_shape, image.shape,
                                    window, scale, p.zeros([self.config.NUM_CLASSES], dtype=np.int32))

    return image, image_meta


def Predict(image):
    weights_path = '/labs/konglab/Steatosis_Seg_DP_xiaoyuan/logs/steatosis20180624T1732/mask_rcnn_steatosis_0060.h5'
    # Inference Configuration
    config = steatosis2.SteatosisInferenceConfig()       
    #DEVICE = "/gpu:0"  # /cpu:0 or /gpu:0
    DEVICE = "/gpu:0"
    # Inspect the model in training or inference modes
    # values: 'inference' or 'training'
    # Only inference mode is supported right now
    TEST_MODE = "inference"

    # Create model in inference mode
    with tf.device(DEVICE):
        model = modellib.MaskRCNN(mode="inference",
                                  model_dir=LOGS_DIR,
                                  config=config)
    # Load weights
    print("Loading weights ", weights_path)
    model.load_weights(weights_path, by_name=True)

    # Load validation dataset
    #dataset = steatosis2.SteatosisDataset()
    #dataset.load_steatosis(DATASET_DIR,image_name)
    #dataset.prepare()

    #for image_id in range(0,len(dataset.image_ids)):
    image, image_meta = modellib.load_image(config,image)
    r = model.detect_molded(np.expand_dims(image, 0), np.expand_dims(image_meta, 0), verbose=1)
    min_score=0.1
    max_score=1.0
    results= r[0]
    print("In steatosis predict, r type is {}".format(type(results)))
    return filer(min_score, max_score,results,image)

def get_ax(rows=1, cols=1, size=16):
    """Return a Matplotlib Axes array to be used in
    all visualizations in the notebook. Provide a
    central point to control graph sizes.
    
    Adjust the size attribute to control how big to render images
    """
    fig, ax = plt.subplots(rows, cols, figsize=(size*cols, size*rows))
    fig.tight_layout()
    return ax


    
