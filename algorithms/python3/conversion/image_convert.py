
from __future__ import print_function
import json
from multiprocessing import Process, JoinableQueue
import openslide
from openslide import open_slide, ImageSlide
from openslide.deepzoom import DeepZoomGenerator
from optparse import OptionParser
import os
import re
import shutil
import sys
from unicodedata import normalize
import PIL.Image

PIL.Image.MAX_IMAGE_PIXELS = 10000000000
if __name__ == '__main__':
    parser = OptionParser(usage='Usage: %prog [options] <slide>')
    (opts, args) = parser.parse_args()
    slidepath = args[0]
    folder_path = os.path.splitext(os.path.basename(slidepath))[0] + "_3d_view"
    # print(folder_path)
    try:  
        os.mkdir(folder_path)
    except FileExistsError:
        print('Directory already exist')
    image = open_slide(slidepath)
    dz = DeepZoomGenerator(image, 2054, 1, True)
    if (dz.level_count > 11):
        level = 11
    else:
        level = 8
    tiledir = folder_path
    cols, rows = dz.level_tiles[level]
    for row in range(rows):
        for col in range(cols):
            tilename = os.path.join(tiledir, '%d_%d.%s' % (col, row, "png"))
            address = (col, row)
            tile = dz.get_tile(level, address)
            tile.save(tilename, "PNG")
            print(tile)
            
    print(dz.level_count)
