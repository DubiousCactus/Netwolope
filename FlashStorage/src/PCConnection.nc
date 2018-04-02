#include "PCConnection.h"

interface PCConnection{
  command void init();
  
  command void receiveMore();
  
  event void initDone();
  
  event void error(PCConnectionError error);
  
  event void fileBegin(uint32_t totalLength);
  
  event void receivedData(uint8_t* data, uint16_t length);
  
  event void fileEnd();
}