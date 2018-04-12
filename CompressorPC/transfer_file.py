#!/usr/bin/python3

import binascii
import serial
import time
import os

from subprocess import call
from progressbar import ProgressBar, Percentage, Bar
from optparse import OptionParser

MSG_RECEIVE_AT_ONCE = "RCV AT ONCE"
MSG_RECEIVE_IN_CHUNKS = "RCV IN CHUNKS"
MSG_READY_TO_RECEIVE = "READY"
MSG_RECEIVE_OK = "RCV OK"

def init_serial(serialPort):
  print("[*] Openning serial port {}".format(serialPort))
  s = serial.Serial()
  s.port = serialPort
  s.baudrate = 115200
  s.bytesize = serial.EIGHTBITS
  s.parity = serial.PARITY_NONE
  s.stopbits = serial.STOPBITS_ONE
  s.timeout = 10 # 10 seconds timeout (is it enough for the mote to compress and send over radio ? lol)
  s.xonxoff = False #disable software flow control

  try:
    s.open()
  except Exception:
    print("error opening serial port")
    exit(1)

  return s

def transfer(image, serialConnection, inChunks):
  print("[*] Transfering file to the mote...")
  if inChunks:
    serialConnection.write(MSG_RECEIVE_IN_CHUNKS.encode('utf-8'))
  else:
    serialConnection.write(MSG_RECEIVE_AT_ONCE.encode('utf-8'))
  
  time.sleep(0.5)
  pbar = ProgressBar(widgets=[Percentage(), Bar(marker='=',left='[',right=']')], maxval=len(image)).start()
  for i, row in enumerate(image):
    written = serialConnection.write(row)
    pbar.update(i + 1)
    time.sleep(0.2)
    
    if inChunks:
      # Now wait until the mote is ready to receive again: when it sends something like OK
      if serialConnection.read(len(MSG_READY_TO_RECEIVE)) != MSG_READY_TO_RECEIVE: # Blocking
        print("[!] Mote didn't send <{}> ! Aborting...".format(MSG_READY_TO_RECEIVE))
        pbar.finish()
        serialConnection.close()
        exit(1)

  pbar.finish()
  
  serialConnection.timeout = 2
  if serialConnection.read(len(MSG_RECEIVE_OK)) != MSG_RECEIVE_OK:
    print("[!] Mote didn't send <{}> ! Sending probably failed...".format(MSG_RECEIVE_OK))

  serialConnection.close()
  exit(1)


def open_file(fileName):
  if not os.path.isfile(options.fileName):
    print("[!] File not found !")
    exit(1)

  print("[*] Opening PGM file")
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
            row = bytearray()
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
parser.add_option("-c", "--chunks", action="store_true", dest="chunks", default=False, help="Send the image in chunks")
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
  transfer(img, s, options.chunks)
