#!/usr/bin/python3

import binascii
import serial
import os

from subprocess import call
from optparse import OptionParser


def init_serial(serialPort):
  print("[*] Openning serial port {}".format(serialPort))
  s = serial.Serial()
  s.port = serialPort
  s.baudrate = 115200
  s.bytesize = serial.EIGHTBITS
  s.parity = serial.PARITY_NONE
  s.stopbits = serial.STOPBITS_ONE
  s.timeout = 0 # Non blocking
  # s.xonxoff = False #disable software flow control

  try:
    s.open()
  except Exception:
    print("error opening serial port")
    exit(1)

  return s

def transfer_in_chunks(fileName):
  return


def transfer_at_once(fileName, serialConnection):
  fileSize = os.stat(fileName).st_size
  packets = list(convert_to_packets(fileName))

  serialConnection.write(to_hex(packet))
  time.sleep(0.5)


def open_file(fileName):
  if not os.path.isfile(options.fileName):
    print("[!] File not found !")
    exit(1)

  pgmFile = open(fileName, 'rb') # Open in binary mode
  try:
    if pgmFile.readline().decode('ascii') == 'P5\n': # Check header
      pgmFile.readline() # Dump the next line, it's a comment
      (width, height) = [int(i) for i in pgmFile.readline().split()]
      depth = int(pgmFile.readline())
      
      try:
        if depth <= 255: # Only 8-bit images

          image = []
          for y in range(height):
            row = []
            for x in range(width):
              row.append(ord(pgmFile.read(1))) # Read one byte and append it to the row
            image.append(row)
          return image
        else:
          raise(AssertionError)
      except AssertionError:
        print("[!] Not an 8-bit image !")
        exit(1)
    else:
      raise(AssertionError)
  except AssertionError:
    print("[!] Not a PGM file !")
    exit(1)



# EXECUTION STARTS HERE
parser = OptionParser()
parser.add_option("-f", "--file", dest="fileName", help="The FILE to transfer to the mote.", metavar="FILE")
parser.add_option("-p", "--port", dest="serialPort", help="The SERIAL_PORT to write to.", metavar="SERIAL_PORT")
(options, args) = parser.parse_args()


if not options.fileName:
  parser.print_help()
  parser.error('Please specify a file to transfer')
elif not options.serialPort:
  parser.print_help()
  parser.error('Please specify a serial port to write to')
else:
  img = open_file(options.fileName)
  s = init_serial(options.serialPort)
  transfer_at_once(img, s)
