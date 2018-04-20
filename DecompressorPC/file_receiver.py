#!/usr/bin/env python

import sys
import tos
import os
from datetime import datetime
from time import sleep
from optparse import OptionParser

if '-h' in sys.argv:
  print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:115200"
  print "      ", sys.argv[0], "network@host:port"
  sys.exit()


AM_MSG_BEGIN_FILE         = 64
AM_MSG_BEGIN_FILE_ACK     = 65
AM_MSG_PARTIAL_DATA       = 66
AM_MSG_ACK_PARTIAL_DATA   = 67
AM_MSG_EOF                = 68
AM_MSG_EOF_ACK            = 69

COMPRESSION_TYPE_NONE = 0
COMPRESSION_TYPE_RUN_LENGTH = 1

PACKET_CAPACITY = 64
debug = '--debug' in sys.argv


class BeginFileMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('type', 'int', 1),
      ('size', 'int', 4),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class BeginFileActMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('type', 'int', 1),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class PartialDataMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('data', 'blob', None),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class PartialDataActMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('nextSeqNo', 'int', 2),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class EndOfFileMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('name', 'int', 4),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class EndOfFileMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('name', 'int', 4),
    ]
    tos.Packet.__init__(self, packet_desc, packet)

class MoteFileReceiver:
  def __init__(self):
    self.am = tos.AM()

  def wait_for_data(self):
    while True:
      packet = self.am.read()
      if packet.type == AM_MSG_PARTIAL_DATA:
        msg = PartialDataMsg(packet.data)
        data = msg.data
        data_size = len(data)
        self.received_data_count += data_size
        print('\n[*] Received data of size %s' % len(data))
        self.current_file.write(bytearray(data))
        self.current_file.flush()
      elif packet.type == AM_MSG_EOF:
        print('\n[*] Received EOF.')
        msg = EndOfFileMsg(packet.data)
        self.current_file.close()
        return
      else:
        print('\n[!] Received an unknown packet: %s' % packet)

  def prepare_file(self):
    folder = 'received_files'
    if not os.path.isdir(folder):
      os.mkdir(folder)
    file_name = 'file-%s.part' % (datetime.today().strftime('%Y-%m-%d-%H-%M-%S'))
    file_path = os.path.join(folder, file_name)
    self.current_file = open(file_path, 'wb')
    self.file_path = file_path
    self.decompressed_file_path = file_path.replace('.part', '.pgm')

  def wait_for_begin_file(self):
    print('\n[*] Listening for incoming files...')
    while True:
      packet = self.am.read()
      if packet.type == AM_MSG_BEGIN_FILE:
        msg = BeginFileMsg(packet.data)
        print('\n[*] New file (%s, %s). Sending acknowledgement...' % (msg.size, msg.type))

        # Send ack
        ack_msg = BeginFileActMsg((msg.type, ))
        self.am.write(ack_msg, AM_MSG_BEGIN_FILE_ACK)

        # Store the message for later use.
        self.begin_file_msg = msg
        self.received_data_count = 0
        return
      else:
        pass

  def decompress_run_length(self):
    print('Decompressing run-length encoded file...')
    in_file = open(self.file_path, 'rb')
    out_file = open(self.decompressed_file_path, 'wb')
    while True:
      byte_array = in_file.read(2)
      if len(byte_array) != 2:
        break
      data = byte_array[0]
      count = int(byte_array[1].encode('hex'), 16)
      out_file.write(bytearray( data * count ))
    in_file.close()
    out_file.close()
    print('Decompressed file: %s' % self.decompressed_file_path)

  def decompress(self):
    compr_type = self.begin_file_msg.type
    if compr_type == COMPRESSION_TYPE_NONE:
      os.rename(self.file_name, self.decompressed_file_path)
    elif compr_type == COMPRESSION_TYPE_RUN_LENGTH:
      self.decompress_run_length()
    else:
      # Uknown compression
      print('Unknown compression: %s' % compr_type)

  def print_summary(self):
    print 'Data written to file: %s' % self.file_path
    original_size = self.begin_file_msg.size
    compressed_size = self.received_data_count
    compression_rate = original_size / float(compressed_size)
    print 'Transferred file size: %s, original %s: Ratio: %s' % (original_size, compressed_size, compression_rate)

  def listen(self):
    self.wait_for_begin_file()
    self.prepare_file()
    self.wait_for_data()
    self.print_summary()
    self.decompress()


parser = OptionParser()
parser.add_option("-d", "--debug", action="store_true", dest="debug", help="Debug mode", default=False, metavar="DEBUG")
(options, args) = parser.parse_args()

server = MoteFileReceiver()
server.listen()

