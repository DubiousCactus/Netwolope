#include "FlashStorage.h"

interface FlashStorage{
  
  command void init(bool erase);
  
  command void read(uint32_t fromIndex, uint8_t* data, uint16_t length);
  
  command void write(uint8_t* data, uint16_t length);
  
  event void initialised(uint32_t size);
  
  event void error(FlashStorageError error);
  
  event void readDone();
  
  event void writeDone();
}