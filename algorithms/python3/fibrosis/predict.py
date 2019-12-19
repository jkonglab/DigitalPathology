import Models
from keras.models import load_model
import cv2
import numpy as np
import random
import os

def predict_return2(X):
# This prediction funtion return prediction 
	n_classes = 2
	model_name = 'fcn8'

	input_width =  256
	input_height = 256
	epoch_number = 1

	modelFns = { 'vgg_segnet':Models.VGGSegnet.VGGSegnet , 'vgg_unet':Models.VGGUnet.VGGUnet , 'vgg_unet2':Models.VGGUnet.VGGUnet2 , 'fcn8':Models.FCN8.FCN8 , 'fcn32':Models.FCN32.FCN32   }
	modelFN = modelFns[ model_name ]
	save_weights_path = '/DP_Share/imageviewer/algorithms/python3/fibrosis/image-segmentation-keras-master.model.9'
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
	seg_img = np.zeros( ( output_height , output_width  ) )
	for c in range(n_classes):
		seg_img[:,:] += ( (pr[:,: ] == c )*( colors[c][0] )).astype('uint8')
	seg_img = cv2.resize(seg_img  , (input_width , input_height ))
	result = []
	for i in range(0,input_width):
		for j in range(0,input_height):
			if(seg_img[i,j]):
				result.append([i,j])
	return result


def predict_return(X):
# This prediction funtion return target contours and the number of target pixels
	n_classes = 2
	model_name = 'fcn8'

	input_width =  256
	input_height = 256
	epoch_number = 1

	modelFns = { 'vgg_segnet':Models.VGGSegnet.VGGSegnet , 'vgg_unet':Models.VGGUnet.VGGUnet , 'vgg_unet2':Models.VGGUnet.VGGUnet2 , 'fcn8':Models.FCN8.FCN8 , 'fcn32':Models.FCN32.FCN32   }
	modelFN = modelFns[ model_name ]
	save_weights_path = '/DP_Share/imageviewer/algorithms/python3/fibrosis/image-segmentation-keras-master.model.9'
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

	# target pixel number
	tp_num = np.sum(pr)
	
	# target contours
	cts, _ = cv2.findContours(pr.astype(dtype=np.uint8), cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
	contours = []
	for ct in cts:
		if len(ct) < 6:
			continue
		contours.append(ct.squeeze().tolist())

	return contours, tp_num




