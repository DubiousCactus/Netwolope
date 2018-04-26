#! /bin/sh
#
# test.sh
# Copyright (C) 2018 transpalette <transpalette@translaptop>
#
# Distributed under terms of the MIT license.
#


make telosb install bsl,/dev/CompressorMote
java net.tinyos.tools.PrintfClient -comm serial@/dev/CompressorMote:115200
