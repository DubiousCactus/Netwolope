#include "PCFileReceiver.h"

interface PCFileReceiver{
  command void init();
  
  command void receiveMore();
  
  command void sendFileBeginAck();
  
  event void initDone();
  
  event void error(PCFileReceiverError error);
  
  event void fileBegin(uint32_t totalLength);
  
  event void receivedData();
  
  event void fileEnd();
}