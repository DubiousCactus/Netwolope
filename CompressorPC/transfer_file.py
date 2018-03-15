import binascii
import os

from itertools import izip_longest
from subprocess import call
from optparse import OptionParser


# Constant for the packet
DATA_SIZE = 20
PACKET_IDX_TYPE = 8
PACKET_IDX_LENGTH = 9
PACKET_TYPE_DATA = 0
PACKET_TYPE_END = 1
PACKET_TEMPLATE = [
  0x00,       #
  0xFF, 0xFF, # destination address
  0x00, 0x00, # source address
  0x16,       # message length, 0x16 => 22
  0x22,       # group id
  0x06,       # handler id
  0x00,       # packet type (0=data, 1=end of message)
  0x00,       # actual data length
  0x00,       # data[0]
  0x00,       # data[1]
  0x00,       # data[2]
  0x00,       # data[3]
  0x00,       # data[4]
  0x00,       # data[5]
  0x00,       # data[6]
  0x00,       # data[7]
  0x00,       # data[8]
  0x00,       # data[9]
  0x00,       # data[10]
  0x00,       # data[11]
  0x00,       # data[12]
  0x00,       # data[13]
  0x00,       # data[14]
  0x00,       # data[15]
  0x00,       # data[16]
  0x00,       # data[17]
  0x00,       # data[18]
  0x00,       # data[19]
]

def grouper(iterable, n, fillvalue=None):
      args = [iter(iterable)] * n
      return izip_longest(*args, fillvalue=fillvalue)


def to_hex(byte_array):
    return ' '.join(map(lambda d: '%0.2X' % d, byte_array))


def create_end_of_stream_packet():
  packet = PACKET_TEMPLATE[:]
  packet[PACKET_IDX_TYPE] = PACKET_TYPE_END
  packet[PACKET_IDX_LENGTH] = 0
  return to_hex(packet)


def convert_to_packets(file_name):
  f = open('data.bin', 'rb')
  image_data = bytearray(f.read())
  f.close()

  # Group byte arrays in groups
  for group in grouper(image_data, DATA_SIZE):
    # Remove all None values at the end of the image data
    data_items = [x for x in group if x is not None]

    # Copy the packet template
    packet = PACKET_TEMPLATE[:]

    # Assign packet type
    packet[PACKET_IDX_TYPE] = PACKET_TYPE_DATA

    # Assign the actual length of the data
    packet[PACKET_IDX_LENGTH] = len(data_items)

    # Data values follow after the data length
    data_idx = PACKET_IDX_LENGTH + 1

    # Set the data bytes
    for item in data_items:
      packet[data_idx] = item
      data_idx += 1

    yield to_hex(packet)


def transfer(file_name):
  file_size = os.stat(file_name).st_size
  packets = list(convert_to_packets(file_name))
  print('File "%s" (%s bytes) is converted to %s packets' % (file_name, file_size, len(packets)))

  CMD = 'java net.tinyos.tools.Send'
  for packet in packets:
    print('Executing "%s %s"' % (CMD, packet))
    call([CMD, packet])

  # Append an end-of-stream packet
  end_packet = create_end_of_stream_packet()
  print('Executing "%s %s"' % (CMD, end_packet))
  call([CMD, end_packet])


parser = OptionParser()
parser.add_option("-f", "--file", dest="file_name", help="The FILE to transfer to the mote.", metavar="FILE")
(options, args) = parser.parse_args()

file_name = options.file_name
if not file_name:
  parser.print_help()
  parser.error('Please specify a file to transfer')
elif not os.path.isfile(file_name):
  parser.error('File "%s" not found' % file_name)
else:
  transfer(file_name)
