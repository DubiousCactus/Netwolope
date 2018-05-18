#include "PCFileSender.h"

interface PCFileSender {
  command void init();
  
  command void sendFileBegin(uint32_t uncompressedSize, uint8_t compressionType);
  
  command void sendPartialData(uint8_t* data, uint8_t size);
  
  command void sendEOF();
  
  event void initDone();
  
  event void error(PCFileSenderError error);
  
  event void partialDataSent();
  
  event void beginFileSent();
}