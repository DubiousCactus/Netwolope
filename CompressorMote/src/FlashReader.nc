/**
 * Reads data from the flash.
 */
interface FlashReader {
  command void prepareRead(uint32_t bytesToRead);
  command void readNextChunk();
  command bool isFinished();
  
  event void chunkRead();
}