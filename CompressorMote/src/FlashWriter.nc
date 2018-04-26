/**
 * Writes data to the flash.
 */
interface FlashWriter {
  /**
   * Prepares to write image data to the flash. 
   * 
   * <p>Once the preparation is done, <code>readyToWrite</code> is signalled.</p>
   * 
   * @imageWidth The width of the image.
   */
  command void prepareWrite(uint16_t imageWidth);

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