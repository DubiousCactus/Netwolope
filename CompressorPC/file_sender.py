#!/usr/bin/env python

import sys
import tos
import os
from time import sleep
from optparse import OptionParser

if '-h' in sys.argv:
  print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:115200"
  print "      ", sys.argv[0], "network@host:port"
  sys.exit()

AM_MSG_BEGIN_FILE       = 128
AM_MSG_ACK_BEGIN_FILE   = 129
AM_MSG_PARTIAL_DATA     = 130
AM_MSG_ACK_PARTIAL_DATA = 131
AM_MSG_EOF              = 132
AM_MSG_ACK_EOF          = 133

PACKET_CAPACITY = 64
debug = '--debug' in sys.argv


class BeginFileMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('width', 'int', 2),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class PartialDataMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('data', 'blob', None),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class EndOfFileMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('size', 'int', 4),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class MoteFileSender:
  def __init__(self):
    self.am = tos.AM()

  def show_progress(self, iteration, total, bar_length=50):
    percent = int(round((iteration / float(total)) * 100))
    nb_bar_fill = int(round((bar_length * percent) / 100))
    bar_fill = '#' * nb_bar_fill
    bar_empty = ' ' * (bar_length - nb_bar_fill)
    sys.stdout.write("\r  [%s] %s%%" % (str(bar_fill + bar_empty), percent))
    sys.stdout.flush()

  def send_message(self, msg, msg_type, ack_type, num_retries = 10):
    #sleep(1)
    self.am.write(msg, msg_type)
    resp = self.am.read(timeout=5)
    if resp:
      if resp.type == ack_type:
        if debug:
          print ' [*] Received expected acknowledgement: ', resp
        return
      else:
        print ' [!] Received unexpected packet', resp
        exit(1)
    else:
      print ' [!] Read timeout'
      exit(1)

  def send_begin_file(self):
    transfer_size = len(self.image_data)
    print "Sending '%s' (%s bytes) to mote..." % (self.file_path, transfer_size)
    msg = BeginFileMsg((self.width, ))
    self.send_message(msg, AM_MSG_BEGIN_FILE, AM_MSG_ACK_BEGIN_FILE)

  def send_next_packet(self, bytes_to_send):
    msg = PartialDataMsg(list(bytes_to_send))
    self.send_message(msg, AM_MSG_PARTIAL_DATA, AM_MSG_ACK_PARTIAL_DATA)

  def send_file_contents(self):
    packet_count = 1
    i = 0
    n_bytes = len(self.image_data)
    while i < n_bytes:
      bytes_to_send = self.image_data[i: i+PACKET_CAPACITY]
      if debug:
        print(' [*] Sending packet #%s' % packet_count)
      else:
        self.show_progress(i, n_bytes)
      self.send_next_packet(bytes_to_send)
      i = i + len(bytes_to_send)
      packet_count += 1

  def send_eof(self):
    if debug:
      print ' [*] Sending EOF'
    msg = EndOfFileMsg((self.file_size, ))
    self.send_message(msg, AM_MSG_EOF, AM_MSG_ACK_EOF)
    self.show_progress(100, 100)

  def prepare_send(self):
    f = open(self.file_path, 'rb')

    # Read the magic number of the file
    file_magic = f.read(3)
    if file_magic != 'P5\n':
      print('File %s is not a PGM file.' % self.file_path)
      exit(1)
    
    # Ignore comment lines
    line = f.readline()
    while line[0] == '#':
      line = f.readline()

    # Line after comment lines gives us image dimensions
    (width, height) = [int(i) for i in line.split()]
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
    self.image_data = bytearray(f.read())
    f.close()
    self.file_size = int(os.stat(self.file_path).st_size)
    self.width = width
    self.height = height

  def send(self, file_path):
    self.file_path = file_path
    self.prepare_send()

    self.send_begin_file()
    self.send_file_contents()
    self.send_eof()
    if debug:
      print 'We are done!'


parser = OptionParser()
parser.add_option("-f", "--file", dest="file_path", help="The FILE to transfer to the mote.", metavar="FILE")
parser.add_option("-d", "--debug", action="store_true", dest="debug", help="Debug mode", default=False, metavar="DEBUG")
(options, args) = parser.parse_args()

if not options.file_path:
  parser.print_help()
  parser.error('Please specify a file to transfer')
else:
  sender = MoteFileSender()
  sender.send(options.file_path)

