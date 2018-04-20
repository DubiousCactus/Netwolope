#include "RadioSender2.h"

interface RadioSender2{
  command void init();
  command void sendPartialData(uint8_t * buffer, uint16_t bufferSize);
  command void sendEOF();
  
  event void initDone();
  event void sendDone();
  event void error(RadioSenderError error);
}
