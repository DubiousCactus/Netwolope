#include "PCConnection.h"

interface PCConnection{
  command void init();
  
  command void receiveMore();
  
  event void initDone();
  
  event void error(PCConnectionError error);
  
  event void receivedData(uint8_t* data, uint16_t length);
  
  event void transmissionBegin(uint32_t totalLength);
}