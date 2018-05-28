#! /bin/sh
#
# test.sh
# Copyright (C) 2018 transpalette <transpalette@translaptop>
#
# Distributed under terms of the MIT license.
#


make telosb install bsl,/dev/Compressor
java net.tinyos.tools.PrintfClient -comm serial@/dev/Compressor:115200
