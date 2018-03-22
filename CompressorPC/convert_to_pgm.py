#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2018 transpalette <transpalette@translaptop>
#
# Distributed under terms of the MIT license.

"""

"""

from skimage import color
from skimage.io import imread, imsave
from skimage.transform import resize
from skimage.exposure import rescale_intensity
from optparse import OptionParser


def convert_to_pgm(fileName):
  img = imread(fileName)
  img = color.rgb2gray(img)
  img = resize(img, (256, 256))
  # img = rescale_intensity(img, out_range = (0, 255))
  newImg = fileName.split(".")[0] + ".pgm"
  imsave(newImg, img)


# EXECUTION STARTS HERE
parser = OptionParser()
parser.add_option("-f", "--file", dest="fileName", help="The FILE to transfer to the mote.", metavar="FILE")
(options, args) = parser.parse_args()


if not options.fileName:
  parser.print_help()
  parser.error('Please specify a file to transfer')
else:
  convert_to_pgm(options.fileName)
