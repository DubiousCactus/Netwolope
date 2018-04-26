/**
 * Reads data from the flash.
 */
interface FlashReader {
  command void prepareRead();
  command void readNextChunk();
  command bool isFinished();
  
  event void chunkRead();
  event void readyToRead(uint16_t imageWidth);
}