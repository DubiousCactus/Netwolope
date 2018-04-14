#include "RadioHeader.h"

interface RadioReceiver{
  command void start();
  event void receivedData(uint8_t * data, uint8_t size);
  event void readyForReceive();
}
