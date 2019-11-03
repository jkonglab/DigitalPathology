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
from mrcnn import utils
from mrcnn.config import Config
import mrcnn.model2 as modellib
import numpy as np
import cv2
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


class SteatosisConfig(Config):
    """Configuration for training on the steatosis segmentation dataset."""
    # Give the configuration a recognizable name
    NAME = "steatosis"

    # Adjust depending on your GPU memory
    IMAGES_PER_GPU = 1

    # Number of classes (including background)
    NUM_CLASSES = 1 + 1  # Background + steatosis

    # Number of training and validation steps per epoch
    STEPS_PER_EPOCH = (161 - 20) // IMAGES_PER_GPU
    VALIDATION_STEPS = max(1, 20 // IMAGES_PER_GPU)

    # Don't exclude based on confidence. Since we have two classes
    # then 0.5 is the minimum anyway as it picks between steatosis and BG
    DETECTION_MIN_CONFIDENCE = 0

    # Backbone network architecture
    # Supported values are: resnet50, resnet101
    BACKBONE = "resnet50"

    # Input image resizing
    # Random crops of size 512x512
    IMAGE_RESIZE_MODE = "crop"
    IMAGE_MIN_DIM = 512
    IMAGE_MAX_DIM = 512
    IMAGE_MIN_SCALE = 2.0

    # Length of square anchor side in pixels
    RPN_ANCHOR_SCALES = (8, 16, 32, 64, 128)

    # ROIs kept after non-maximum supression (training and inference)
    POST_NMS_ROIS_TRAINING = 1000
    POST_NMS_ROIS_INFERENCE = 2000

    # Non-max suppression threshold to filter RPN proposals.
    # You can increase this during training to generate more propsals.
    RPN_NMS_THRESHOLD = 0.9

    # How many anchors per image to use for RPN training
    RPN_TRAIN_ANCHORS_PER_IMAGE = 64

    # Image mean (RGB)
    MEAN_PIXEL = np.array([43.53, 39.56, 48.22])

    # If enabled, resizes instance masks to a smaller size to reduce
    # memory load. Recommended when using high-resolution images.
    USE_MINI_MASK = True
    MINI_MASK_SHAPE = (56, 56)  # (height, width) of the mini-mask

    # Number of ROIs per image to feed to classifier/mask heads
    # The Mask RCNN paper uses 512 but often the RPN doesn't generate
    # enough positive proposals to fill this and keep a positive:negative
    # ratio of 1:3. You can increase the number of proposals by adjusting
    # the RPN NMS threshold.
    TRAIN_ROIS_PER_IMAGE = 128

    # Maximum number of ground truth instances to use in one image
    MAX_GT_INSTANCES = 200

    # Max number of final detections per image
    DETECTION_MAX_INSTANCES = 400

class SteatosisInferenceConfig(SteatosisConfig):
    # Set batch size to 1 to run one image at a time
    GPU_COUNT = 1 #2
    IMAGES_PER_GPU = 1 #6
    # Don't resize imager for inferencing
    IMAGE_RESIZE_MODE = "pad64"
    # Non-max suppression threshold to filter RPN proposals.
    # You can increase this during training to generate more propsals.
    RPN_NMS_THRESHOLD = 0.7

def Predict(image):
    weights_path = '/DP_Share/imageviewer/algorithms/python3/steatosis_neural_net/mask_rcnn_coco.h5'
    # Inference Configuration
    config = SteatosisInferenceConfig()       
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
    #fig, ax = plt.subplots(rows, cols, figsize=(size*cols, size*rows))
    #fig.tight_layout()
    #return ax


    
