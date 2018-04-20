#include "RadioReceiver.h"

interface RadioReceiver{
  command void init();
  
  event void initDone();
  event void receivedData(uint8_t * data, uint8_t size);
  event void error(RadioReceiverError error);
}
