interface CircularBufferWriter{
  /**
   * Clears the buffer.
   */
  command void clear();
  
  /**
   * Gets number of free bytes that can be written. 
   */
  command uint16_t getFreeSpace();
  
  /**
   * Writes a single byte.
   */
  command error_t write(uint8_t byte);
  
  /**
   * Writes a chunk of bytes.
   */
  command error_t writeChunk(uint8_t * buffer, uint16_t size);
}