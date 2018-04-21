#include "OnlineCompressionAlgorithm.h"

interface OnlineCompressionAlgorithm{
  command void init();
  command void fileBegin(uint32_t totalLength);
  command void compress();
  command void fileEnd();
  command uint8_t getCompressionType();
  
  event void initDone();
  event void compressed();
  event void compressDone();
  event void error(CompressionError error);
}