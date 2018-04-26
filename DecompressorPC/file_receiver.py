#!/usr/bin/env python

import sys
import tos
import os
from datetime import datetime
from time import sleep
from optparse import OptionParser
from decompressors import DecompressorBase

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

  def show_progress(self, iteration, total, bar_length=50):
    percent = int(round((iteration / float(total)) * 100))
    nb_bar_fill = int(round((bar_length * percent) / 100))
    bar_fill = '#' * nb_bar_fill
    bar_empty = ' ' * (bar_length - nb_bar_fill)
    sys.stdout.write("\r  [%s] %s%%" % (str(bar_fill + bar_empty), percent))
    sys.stdout.flush()

  def wait_for_data(self):
    self.start_time = datetime.now()
    self.no_packets = 0
    while True:
      packet = self.am.read()
      if packet.type == AM_MSG_PARTIAL_DATA:
        msg = PartialDataMsg(packet.data)
        data = msg.data
        data_size = len(data)
        self.received_data_count += data_size
        self.no_packets += 1
        #print('\n[*] Received data of size %s' % len(data))
        self.current_file.write(bytearray(data))
        self.current_file.flush()
        self.show_progress(self.received_data_count, self.file_size)
      elif packet.type == AM_MSG_EOF:
        self.end_time = datetime.now()
        #print('\n[*] Received EOF.')
        msg = EndOfFileMsg(packet.data)
        self.current_file.close()
        self.show_progress(100, 100)
        return
      else:
        print('\n[!] Received an unknown packet: %s' % packet)

  def prepare_file(self):
    folder = 'received_files'
    if not os.path.isdir(folder):
      os.mkdir(folder)
    file_name = 'file-%s.raw' % (datetime.today().strftime('%Y-%m-%d-%H-%M-%S'))
    file_path = os.path.join(folder, file_name)
    self.current_file = open(file_path, 'wb')
    self.file_path = file_path
    self.decompressed_file_path = file_path.replace('.raw', '.pgm')

  def wait_for_begin_file(self):
    print('\n[*] Listening for incoming files...')
    while True:
      packet = self.am.read()
      if packet.type == AM_MSG_BEGIN_FILE:
        msg = BeginFileMsg(packet.data)
        self.compression_type = msg.type
        self.image_width = msg.size
        self.file_size = self.image_width ** 2
        self.received_data_count = 0
        self.compression_name = DecompressorBase.type_to_str(self.compression_type)

        print('\n[*] Received begin file (%s bytes, %s)...' % (self.file_size, self.compression_name))

        # Send ack
        ack_msg = BeginFileActMsg((msg.type, ))
        self.am.write(ack_msg, AM_MSG_BEGIN_FILE_ACK)

        return
      else:
        pass

  def decompress(self):
    DecompressorBase.decompress(
      self.compression_type,
      self.file_path,
      self.image_width
    )

  def print_summary(self):
    print '\n [*] Data written to file: %s' % self.file_path
    original_size = self.file_size
    compressed_size = self.received_data_count
    compression_rate = original_size / float(compressed_size)
    print 'Transferred file size: %s. Original size: %s: Ratio: %s' % (compressed_size, original_size, compression_rate)
    print 'Number of packets: %s' % self.no_packets
    time_diff = self.end_time - self.start_time
    print 'Seconds: %s' % time_diff.seconds

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

