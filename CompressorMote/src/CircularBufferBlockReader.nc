interface CircularBufferBlockReader{
  command void prepare(uint16_t imageWidth, uint8_t blockSize);
  command void readNextBlock(uint8_t * buffer);
  command bool hasMoreBlocks();
}