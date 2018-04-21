interface CircularBufferWriter{
  command void clear();
  command uint16_t getFreeSpace();
  command error_t write(uint8_t byte);
  command error_t writeChunk(uint8_t * buffer, uint16_t size);
}