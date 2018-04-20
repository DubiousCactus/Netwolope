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


AM_MSG_BEGIN_TRANSMIT     = 128
AM_MSG_ACK_BEGIN_TRANSMIT = 129
AM_MSG_PARTIAL_DATA       = 130
AM_MSG_ACK_PARTIAL_DATA   = 131
AM_MSG_EOF                = 132
AM_MSG_ACK_END_TRANSMIT   = 133

PACKET_CAPACITY = 64
debug = '--debug' in sys.argv


class BeginFileMsg(tos.Packet):
  def __init__(self, packet = None):
    packet_desc = [
      ('totalSize', 'int', 4),
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
      ('totalSize', 'int', 4),
    ]
    tos.Packet.__init__(self, packet_desc, packet)


class MoteFileSender:
  def __init__(self):
    self.am = tos.AM()

  def send_message(self, msg, msg_type, ack_type, num_retries = 10):
    #sleep(1)
    counter = 0
    self.am.write(msg, msg_type)
    resp = self.am.read(timeout=5)
    if resp:
      if resp.type == ack_type:
        print ' [*] Received expected acknowledgement: ', resp
        return
      else:
        print ' [!] Received unexpected packet', resp
        exit(1)
    else:
      print ' [!] Read timeout'
      exit(1)

  def send_begin_file(self):
    msg = BeginFileMsg((self.file_size, ))
    self.send_message(msg, AM_MSG_BEGIN_TRANSMIT, AM_MSG_ACK_BEGIN_TRANSMIT)

  def send_next_packet(self, bytes_to_send):
    msg = PartialDataMsg(list(bytes_to_send))
    self.send_message(msg, AM_MSG_PARTIAL_DATA, AM_MSG_ACK_PARTIAL_DATA)

  def send_file_contents(self):
    f = open(self.file_name, 'rb')
    self.data_bytes = bytearray(f.read())
    f.close()
    counter = 1
    i = 0
    while i < len(self.data_bytes):
      bytes_to_send = self.data_bytes[i: i+PACKET_CAPACITY]
      print(' [*] Sending packet #%s' % counter)
      self.send_next_packet(bytes_to_send)
      i = i + len(bytes_to_send)
      counter += 1

  def send_eof(self):
    print ' [*] Sending EOF'
    msg = EndOfFileMsg((self.file_size, ))
    self.send_message(msg, AM_MSG_EOF, AM_MSG_ACK_END_TRANSMIT)

  def send(self, file_name):
    self.file_name = file_name
    self.file_size = int(os.stat(self.file_name).st_size)

    print "Sending '%s' (%s bytes) to mote..." % (file_name, self.file_size)

    self.send_begin_file()
    self.send_file_contents()
    self.send_eof()
    print 'We are done!'


parser = OptionParser()
parser.add_option("-f", "--file", dest="file_name", help="The FILE to transfer to the mote.", metavar="FILE")
parser.add_option("-d", "--debug", action="store_true", dest="debug", help="Debug mode", default=False, metavar="DEBUG")
(options, args) = parser.parse_args()

if not options.file_name:
  parser.print_help()
  parser.error('Please specify a file to transfer')
else:
  sender = MoteFileSender()
  sender.send(options.file_name)

