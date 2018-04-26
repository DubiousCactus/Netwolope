#include "OnlineCompressionAlgorithm.h"

interface OnlineCompressionAlgorithm {
  command uint8_t getCompressionType();
  command void fileBegin(uint16_t imageWidth);
  command void compress(bool last);

  event void compressed();
  event void error(CompressionError error);
}
