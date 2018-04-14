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

PACKET_CAPACITY = 64
debug = '--debug' in sys.argv


class BeginFileMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('type', 'int', 1),
      ('name', 'int', 4),
      ('size', 'int', 4),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class BeginFileActMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('type', 'int', 1),
      ('name', 'int', 4),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class PartialDataMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('seqNo', 'int', 2),
      ('flags', 'int', 1),
      ('dataSize', 'int', 1),
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
        data = msg.data[:msg.dataSize]
        print('\n[*] Received data: %s' % data)
        self.current_file.write(bytearray(data))
      elif packet.type == AM_MSG_EOF:
        print('\n[*] Received EOF.')
        msg = EndOfFileMsg(packet.data)
        self.current_file.close()
        print 'Data written to file: %s' % self.file_path
        return
      else:
        print('\n[!] Received an unknown packet: %s' % packet)

  def prepare_file(self):
    folder = 'received_files'
    if not os.path.isdir(folder):
      os.mkdir(folder)
    file_name = '%s-%s.pgm' % (datetime.today().strftime('%Y-%m-%d-%H-%M-%S'), self.begin_file_msg.name)
    file_path = os.path.join(folder, file_name)
    self.current_file = open(file_path, 'wb')
    self.file_path = file_path

  def wait_for_begin_file(self):
    while True:
      print('\n[*] Listening for incoming files...')
      packet = self.am.read()
      if packet.type == AM_MSG_BEGIN_FILE:
        msg = BeginFileMsg(packet.data)
        print('\n[*] Received BEGIN_FILE. Sending acknowledgement...')

        # Send ack
        ack_msg = BeginFileActMsg((msg.type, msg.name))
        self.am.write(ack_msg, AM_MSG_BEGIN_FILE_ACK)

        # Store the message for later use.
        self.begin_file_msg = msg
        return
      else:
        print('\n[!] Received an unknown packet: %s' % packet)

  def listen(self):
    while True:
      self.wait_for_begin_file()
      self.prepare_file()
      self.wait_for_data()


parser = OptionParser()
parser.add_option("-d", "--debug", action="store_true", dest="debug", help="Debug mode", default=False, metavar="DEBUG")
(options, args) = parser.parse_args()

server = MoteFileReceiver()
server.listen()

