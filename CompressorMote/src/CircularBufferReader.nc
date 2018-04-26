interface CircularBufferReader{
  /**
   * Gets the number of available bytes in the buffer.
   */
  command uint16_t available();
  
  /**
   * Reads a single byte.
   */
  command error_t read(uint8_t * singleByte);
  
  /**
   * Reads a chunk of bytes into the given buffer.
   * 
   * @param buffer  Buffer to read bytes into.
   * @param size    Number of bytes to read.
   */
  command error_t readChunk(uint8_t * buffer, uint16_t size);
}