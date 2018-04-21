/**
 * Write data to the flash.
 */
interface FlashWriter {
  command void prepareWrite(uint32_t bytesToRead);

  command void writeNextChunk();

  event void chunkWritten();
  
  event void readyToWrite();
}