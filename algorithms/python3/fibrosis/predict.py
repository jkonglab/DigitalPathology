import argparse
import Models
from keras.models import load_model
import glob
import cv2
import numpy as np
import random
import os
import scipy
def predict_return(X):
# This prediction funtion return prediction 
	n_classes = 2
	model_name = 'fcn8'

	input_width =  256
	input_height = 256
	epoch_number = 1

	modelFns = { 'vgg_segnet':Models.VGGSegnet.VGGSegnet , 'vgg_unet':Models.VGGUnet.VGGUnet , 'vgg_unet2':Models.VGGUnet.VGGUnet2 , 'fcn8':Models.FCN8.FCN8 , 'fcn32':Models.FCN32.FCN32   }
	modelFN = modelFns[ model_name ]
	save_weights_path = '/labs/konglab/Fibrosis_Seg_DP_xiaoyuan/FCN8_fibrosis/image-segmentation-keras-master.model.9'
	m = modelFN( n_classes , input_height=input_height, input_width=input_width   )
	m.load_weights(  save_weights_path  )
	m.compile(loss='categorical_crossentropy',
      	optimizer= 'adadelta' ,
      	metrics=['accuracy'])

	output_height = 256
	output_width = 256
	colors = [(0,0,0),(255,255,255)]
	pr = m.predict( np.array([X]) )[0]
	pr = pr.reshape(( output_height ,  output_width , n_classes ) ).argmax( axis=2 )
	#seg_img = np.zeros( ( output_height , output_width , 3  ) )
	seg_img = np.zeros( ( output_height , output_width  ) )
	for c in range(n_classes):
		seg_img[:,:] += ( (pr[:,: ] == c )*( colors[c][0] )).astype('uint8')
		#seg_img[:,:,1] += ((pr[:,: ] == c )*( colors[c][1] )).astype('uint8')
		#seg_img[:,:,2] += ((pr[:,: ] == c )*( colors[c][2] )).astype('uint8')
	seg_img = cv2.resize(seg_img  , (input_width , input_height ))
	#print(seg_img.shape)
	result = []
	#mask = cv2.cvtColor(seg_img,cv2.COLOR_BGR2GRAY)
	#ret, mask = cv2.threshold(seg_img,127,255,cv2.THRESH_BINARY)
	for i in range(0,input_width):
		for j in range(0,input_height):
			if(seg_img[i,j]):
				result.append([i,j])
	return result