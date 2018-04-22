#include "OnlineCompressionAlgorithm.h"

interface OnlineCompressionAlgorithm{
  command uint8_t getCompressionType();
  command void fileBegin(uint32_t totalLength);
  command void compress(bool last);

  event void compressed();
  event void error(CompressionError error);
}