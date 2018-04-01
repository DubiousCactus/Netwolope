interface FlashStorage{
  
  command void init(bool erase);
  
  command void write(uint8_t* data, uint16_t length);
  
  event void initialised(uint32_t size);
  
  event void error(error_t error);
  
  event void writeDone();
}