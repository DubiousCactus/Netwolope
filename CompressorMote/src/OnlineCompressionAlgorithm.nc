#include "OnlineCompressionAlgorithm.h"

interface OnlineCompressionAlgorithm{
  command void init();
  command void fileBegin(uint32_t totalLength);
  command void compress(uint8_t* data, uint16_t length);
  command void fileEnd();
  command uint8_t getCompressionType();
  
  event void initDone();
  event void compressed(uint8_t* compressedData, uint16_t length);
  event void error(CompressionError error);
}