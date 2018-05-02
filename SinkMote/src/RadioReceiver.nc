#include "RadioReceiver.h"

interface RadioReceiver{
  command void init();
  
  event void initDone();
  event void receivedFileBegin(uint32_t uncompressedSize, uint8_t compressionType);
  event void receivedData(uint8_t *data, uint16_t size);
  event void receivedEOF();
  event void error(RadioReceiverError error);
}
