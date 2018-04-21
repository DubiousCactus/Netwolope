#include "RadioSender.h"

interface RadioSender{
  command void init();
  command void sendFileBegin(uint32_t uncompressedSize, uint8_t compressionType);
  command void sendPartialData();
  command void sendEOF();
  
  event void initDone();
  event void sendDone();
  event void fileBeginSent();
  event void error(RadioSenderError error);
}
