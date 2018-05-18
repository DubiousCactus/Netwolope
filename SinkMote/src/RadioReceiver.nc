#include "RadioReceiver.h"

interface RadioReceiver{
  command void init();
  command void sendPartialDataAckMsg();
  command void sendEOFAckMsg();
  command void sendBeginFileAckMsg();
  
  event void initDone();
  event void receivedFileBegin(uint32_t uncompressedSize, uint8_t compressionType);
  event void receivedData(uint8_t * data, uint8_t size);
  event void receivedEOF();
  event void error(RadioReceiverError error);
}
