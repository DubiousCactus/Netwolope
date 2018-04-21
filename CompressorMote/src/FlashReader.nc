/**
 * Read data from the flash.
 */
interface FlashReader {
  command void prepareRead(uint32_t bytesToRead);
  command bool readNextChunk();
  
  event void chunkRead();
  event void readDone();
}