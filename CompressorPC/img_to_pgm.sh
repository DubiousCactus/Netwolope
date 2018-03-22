#! /bin/sh

convert $1 -resize 256 -colorspace GRAY -depth 8 converted_image.pgm
