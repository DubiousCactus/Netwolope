#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2018 transpalette <transpalette@translaptop>
#
# Distributed under terms of the MIT license.

"""
Takes a PGM file as input and saves the image data in a raw file
"""

import sys
import os

if '-h' in sys.argv:
  print "Usage:", sys.argv[0], "<input_file>", "<output_file>"

def trim_file(input_file, output_file):
    f = open(input_file, 'rb')

    # Read the magic number of the file
    file_magic = f.read(3)
    if file_magic != 'P5\n':
      print('File %s is not a PGM file.' % self.file_path)
      exit(1)

    # Second line is the comment line, just ignore it
    f.readline()

    # Third line gives us image dimensions
    (width, height) = [int(i) for i in f.readline().split()]
    if width != height:
      print('Image dimensions %sx%s must be square.' % (width, height))
      exit(1)
    if width > 256:
      print('Image %sx%s is too large. Max is 256x256.' % (width, height))
      exit(1)

    depth = int(f.readline())
    if depth > 255:
      print('Only 8-bit images can be sent.' % depth)
      exit(1)

    # Read image data
    image_data = bytearray(f.read())
    f.close()
    file_size = int(os.stat(input_file).st_size)

    o = open(output_file, "wb")
    o.write(image_data)
    o.close()
    print('Done.')

if len(sys.argv) < 3:
  print "Usage:", sys.argv[0], "<input_file>", "<output_file>"
else:
    trim_file(sys.argv[1], sys.argv[2])
