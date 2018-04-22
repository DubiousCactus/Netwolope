#! /bin/sh

make telosb install bsl,/dev/ttyUSB0

java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:115200
