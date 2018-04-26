#!/usr/bin/env python
import subprocess
from itertools import izip
from datetime import datetime

COMPRESSION_TYPE_NONE = 0
COMPRESSION_TYPE_RUN_LENGTH = 1
COMPRESSION_TYPE_BLOCK_TRUNC = 2
COMPRESSION_TYPE_ROSS = 3

class DecompressorBase:
  def __init__(self):
    pass

  def _decompress(self, image_data, file_path):
    raise Exception('Subclass should implement this method')

  def _name(self):
    raise Exception('Subclass should implement this method')

  def begin(self, file_path, image_width):
    in_file = open(file_path, 'rb')
    compressed_data = in_file.read()
    in_file.close()

    image_data = self._decompress(compressed_data, file_path)

    # ROSS takes care of that ;)
    if image_data:
        out_file_path = file_path + '.pgm'
        out_file = open(out_file_path, 'wb')
        out_file.write('P5\n')
        out_file.write('#\n')
        out_file.write('%s %s\n' % (image_width, image_width))
        out_file.write('255\n')
        out_file.write(bytearray(image_data))
        out_file.close()

  @staticmethod
  def type_to_str(compression_type):
     d = DecompressorBase.get_decompressor(compression_type)
     return d._name()

  @staticmethod
  def get_decompressor(compression_type):
    if compression_type == COMPRESSION_TYPE_NONE:
      return NoCompression()
    elif compression_type == COMPRESSION_TYPE_RUN_LENGTH:
      return RunLengthDecompressor()
    elif compression_type == COMPRESSION_TYPE_BLOCK_TRUNC:
      return BlockTruncationDecompressor()
    elif compression_type == COMPRESSION_TYPE_ROSS:
        return RossDecompressor()
    else:
      return UnknownDecompressor()

  @staticmethod
  def decompress(compression_type, file_path, image_width):
    compressor = DecompressorBase.get_decompressor(compression_type)
    compressor.begin(file_path, image_width)


class UnknownDecompressor(DecompressorBase):
  def __init__(self):
    DecompressorBase.__init__(self)

  def _name(self):
    return 'Unknown'

  def _decompress(self, compressed_data, file_path):
    return compressed_data


class NoCompression(DecompressorBase):
  def __init__(self):
    DecompressorBase.__init__(self)

  def _name(self):
    return 'No compression'

  def _decompress(self, compressed_data, file_path):
    return compressed_data


class RunLengthDecompressor(DecompressorBase):
  def __init__(self):
    DecompressorBase.__init__(self)

  def _name(self):
    return 'Run-length'

  def _decompress(self, compressed_data, file_path):
    if len(compressed_data) % 2 != 0:
      raise Exception('Data size must be even!')

    print('Decompressing run-length encoded file...')
    out_buffer = []
    pairs = izip(*[iter(compressed_data)]*2)
    for pair in pairs:
      data = pair[0]
      count = int(pair[1].encode('hex'), 16)
      out_buffer += [data] * count
    return out_buffer

class BlockTruncationDecompressor(DecompressorBase):
  def __init__(self):
    DecompressorBase.__init__(self)

  def _name(self):
    return 'Block Truncation'

  def _get_bit(self, value, position):
    return ((1 << position) & value) >> position

  def _decompress(self, compressed_data, file_path):
    if len(compressed_data) % 2 != 0:
      raise Exception('Data size must be even!')

    print('Decompressing using block truncation...')
    out_buffer = []
    tuples = izip(*[iter(compressed_data)]*4)
    for tup in tuples:
      a = tup[0]
      b = tup[1]
      hex1 = tup[2]
      hex2 = tup[3]

      for i in xrange(8):
        bit = self._get_bit(hex1, i)
        if bit == 1:
          out_buffer.append(a)
        else:
          out_buffer.append(b)
      for i in xrange(8):
        bit = self._get_bit(hex2, i)
        if bit == 1:
          out_buffer.append(a)
        else:
          out_buffer.append(b)
    return out_buffer


class RossDecompressor(DecompressorBase):
  def  __init__(self):
    DecompressorBase.__init__(self)

  def _name(self):
    return 'ROSS'

  def _decompress(self, compressed_data, file_path):
      # Call ross_decompression
      file_name = 'ROSS-decompressed-%s.pgm' % (datetime.today().strftime('%Y-%m-%d-%H-%M-%S'))
      subprocess.call('./ross_decompression ' + file_path + ' ' + file_name, shell=True)

      return None
