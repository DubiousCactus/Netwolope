/**
 * Writes data to the flash.
 */
interface FlashWriter {
  /**
   * Prepares to write a file to the flash. 
   * 
   * <p>Once the preparation is done, <code>readyToWrite</code> is signalled.</p>
   * 
   * @fileSize The size of the file that needs to be written on the flash.
   */
  command void prepareWrite(uint32_t fileSize);

  /**
   * Writes next chunk of bytes from the buffer to the flash.
   */
  command void writeNextChunk();

  /**
   * Signalled when the flash has been prepared to write a file.
   */
  event void readyToWrite();

  /**
   * Signalled when chunk have been written to the flash successfully.
   */
  event void chunkWritten();
}