interface CircularBufferReader{
  command uint16_t available();
  command error_t read(uint8_t * singleByte);
  command error_t readChunk(uint8_t * buffer, uint16_t size);
}