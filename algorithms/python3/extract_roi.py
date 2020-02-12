import os
import sys
from PIL import Image

def preprocess(raw_input, output_file_path, parameters):
    return raw_input

def postprocess(main_output, output_file_path):
    roi = main_output
    roi.save(os.path.join(output_file_path, 'output_roi.png'))
    f = open(os.path.join(output_file_path, 'output.txt'), 'w')
    f.close()

def main(img, params):
    return img #return ROI from wholeslide


# import openslide
# from openslide import open_slide
# import os
# import sys
# from PIL import Image

# def main(argv):
    # input_file_path = argv[0] 
    # input_file_name = argv[1]
    # output_file_path = argv[2] 
    # tile_x = int(argv[3])
    # tile_y = int(argv[4])
    # tile_width = int(argv[5])
    # tile_height = int(argv[6])

    # input_image = os.path.join(input_file_path, input_file_name)

    # slide = open_slide(input_image)

    # roi = slide.read_region((tile_x,tile_y), 0, (tile_width, tile_height)) #annotation coordinates and size
    # roi.save(os.path.join(output_file_path, 'output_roi.png'))

# def graceful_str2int(string):
	# try:
		# return int(string)
	# except ValueError:
		# return 0

# if __name__ == "__main__":
	# main(sys.argv[1:])