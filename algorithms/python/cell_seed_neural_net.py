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

	output = json.dumps(np.asarray(main_output).T.tolist())

	with open(output_file_path, 'w') as outfile:
  		outfile.write(output)
	return True


def main(input, parameters):
	input_var = T.tensor4('inputs')
	box_size = 37

	with np.load('./cell_seed_neural_net/my_trained.npz') as f:
		param_values = [f['arr_%d' % i] for i in range(len(f.files))]

	network = pickle.load(open('./cell_seed_neural_net/my_network.dpkl', 'rb'))

	lasagne.layers.set_all_param_values(network, param_values)
	val_prediction = lasagne.layers.get_output(network, input_var, deterministic=True)

	eval_img = input
	eval_img = eval_img.mean(axis=2)

	def normalize(data, mu, sigma):
		return (data - mu) / sigma

	eval_img = normalize(eval_img, eval_img.mean(), eval_img.std())

	eval_fn = theano.function([input_var], val_prediction)
	output = np.zeros((eval_img.shape[0], eval_img.shape[1], 2))

	margin = box_size // 2
	for x in range(margin, eval_img.shape[0]-margin):
		print('x: ' + str(x))
		for y in range(margin, eval_img.shape[1]-margin):
			patch = eval_img[y-margin:y+margin+1, x-margin:x+margin+1]
			patch = patch.reshape(1, 1, box_size, box_size)
			output[x, y, :] = eval_fn(patch)

	heatmap = filters.gaussian_filter(output[:, :, 1], 1)
	seg = heatmap > 0.5
	detections = np.where(np.multiply(seg, heatmap == filters.maximum_filter(heatmap, 3)))

	fig, ax = plt.subplots()
	ax.imshow(eval_img, interpolation='nearest', cmap=plt.cm.gray)
	plt.plot(detections[0], detections[1], 'b.', markersize=4, mew=3)

	ax.axis('image')
	ax.set_xticks([])
	ax.set_yticks([])
	plt.savefig(fname='demo.tif')

	return detections
