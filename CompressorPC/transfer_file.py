import binascii
import serial
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


def to_hex(byteArray):
    return ' '.join(map(lambda d: '%0.2X' % d, byteArray))


def create_end_of_stream_packet():
  packet = PACKET_TEMPLATE[:]
  packet[PACKET_IDX_TYPE] = PACKET_TYPE_END
  packet[PACKET_IDX_LENGTH] = 0
  return to_hex(packet)


def convert_to_packets(fileName):
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


def init_serial(serialPort):
  s = serial.Serial()
  s.port = serialPort
  s.baudrate = 115200
  s.bytesize = serial.EIGHTBITS
  s.parity = serial.PARITYNONE
  s.stopbits = serial.STOPBITS_ONE
  s.timeout = 0 # Non blocking
  # s.xonxoff = False #disable software flow control

  try:
    s.open()
  except Exception, e:
    print("error  opening serial port: " + str(e))
    exit(1)


def transfer_in_chunks(fileName):
  return


def transfer_at_once(fileName):
  fileSize = os.stat(fileName).st_size
  packets = list(convert_to_packets(fileName))
  print('File "%s" (%s bytes) is converted to %s packets' % (fileName, fileSize, len(packets)))

  for packet in packets:
    print('Executing "%s %s"' % (CMD, packet))
    call([CMD, packet])

  # Append an end-of-stream packet
  EOSPacket = create_end_of_stream_packet()
  print('Executing "%s %s"' % (CMD, EOSPacket))
  call([CMD, EOSPacket])



# EXECUTION STARTS HERE
parser = OptionParser()
parser.add_option("-f", "--file", dest="fileName", help="The FILE to transfer to the mote.", metavar="FILE")
parser.add_option("-p", "--port", dest="serialPort", help="The SERIAL_PORT to write to.", metavar="SERIAL_PORT")
(options, args) = parser.parse_args()


if not options.fileName:
  parser.print_help()
  parser.error('Please specify a file to transfer')
elif not os.path.isfile(options.fileName):
  parser.error('File "%s" not found' + options.fileName)
elif not options.serialPort:
  parser.print_help()
  parser.error('Please specify a serial port to write to')
else:
  init_serial(options.serialPort)
  transfer(options.fileName)
