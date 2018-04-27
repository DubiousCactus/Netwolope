#!/usr/bin/env python
import sys
import os
from itertools import izip

COMPRESSION_TYPE_NONE = 0
COMPRESSION_TYPE_RUN_LENGTH = 1
COMPRESSION_TYPE_BLOCK_TRUNC = 2
COMPRESSION_TYPE_ROSS = 3
COMPRESSION_TYPE_BLOCK = 4

class DecompressorBase:
  def __init__(self):
    pass

  def _decompress(self, image_data):
    raise Exception('Subclass should implement this method')

  def _name(self):
    raise Exception('Subclass should implement this method')

  def begin(self, file_path, image_width):
    in_file = open(file_path, 'rb')
    compressed_data = in_file.read()
    in_file.close()

    image_data = self._decompress(compressed_data, image_width)

    out_file_path = file_path + '.pgm'
    out_file = open(out_file_path, 'wb')
    out_file.write('P5\n')
    out_file.write('#\n')
    out_file.write('%s %s\n' % (image_width, image_width))
    out_file.write('255\n')
    out_file.write(bytearray(image_data))
    out_file.close()

  def blocks_to_linear(self, data, image_width, block_size=4):
    block_array_size = block_size * block_size
    blocks_per_row = image_width / block_size

    out_buffer = []
    data_array = izip(*[iter(data)]* image_width*block_size)

    for block_row in data_array:
      result = []
      for i in range(block_size):
        result.append([])

      block_array = izip(*[iter(block_row)]*block_array_size)

      for tup in block_array:
        arr = izip(*[iter(tup)]*block_size)
        for idx, t2 in enumerate(arr):
          result[idx].extend(t2)
      for l in result:
        out_buffer.extend(l)
    return out_buffer

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
    elif compression_type == COMPRESSION_TYPE_BLOCK:
      return BlockDecompressor()
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

  def _decompress(self, compressed_data):
    return compressed_data


class BlockDecompressor(DecompressorBase):
  def __init__(self):
    DecompressorBase.__init__(self)

  def _name(self):
    return 'Block Compression'

  def _decompress(self, compressed_data, image_width):
    return self.blocks_to_linear(compressed_data, image_width, block_size=4)


class NoCompression(DecompressorBase):
  def __init__(self):
    DecompressorBase.__init__(self)

  def _name(self):
    return 'No compression'

  def _decompress(self, compressed_data, image_width):
    return compressed_data


class RunLengthDecompressor(DecompressorBase):
  def __init__(self):
    DecompressorBase.__init__(self)

  def _name(self):
    return 'Run-length'

  def _decompress(self, compressed_data):
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

  def _decompress(self, compressed_data, image_width):
    if len(compressed_data) % 2 != 0:
      raise Exception('Data size must be even!')

    print('Decompressing using block truncation...')
    out_buffer = []
    tuples = izip(*[iter(compressed_data)]*4)
    for tup in tuples:
      a = tup[0]
      b = tup[1]
      a = int(tup[0].encode('hex'), 16)
      b = int(tup[1].encode('hex'), 16)
      hex1 = int(tup[2].encode('hex'), 16)
      hex2 = int(tup[3].encode('hex'), 16)

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
    return self.blocks_to_linear(out_buffer, image_width, block_size=4)
