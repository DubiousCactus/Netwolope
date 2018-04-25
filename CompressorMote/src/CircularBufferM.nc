#include "printf.h"

generic module CircularBufferM(uint16_t CAPACITY) {
  provides {
    interface CircularBufferReader as Reader;
    interface CircularBufferWriter as Writer;
    interface CircularBufferBlockReader as BlockReader;
  }
}
implementation{
  uint8_t _buf[CAPACITY];
  uint16_t _start = 0;
  uint16_t _end = 0;
  
  uint8_t _blockSize = 0;
  uint16_t _blockRowSize = 0;
  uint16_t _blocksPerRow = 0;
  uint16_t _imageWidth = 0;
  uint16_t _blockIndex = 0;
  
  inline uint16_t available() {
    if (_start <= _end)
      return _end - _start;
    else
      return CAPACITY - _start + _end;
  }
  
  inline uint16_t getFreeSpace() { 
    return CAPACITY - available() - 1; 
  }

  command uint16_t Reader.available(){
    return available();
  }
  
  command error_t Reader.read(uint8_t *byte){
    if (_start == _end) {
      // Nothing in the buffer
      return FAIL;
    } else {
      *byte = _buf[_start++];
      if (_start == CAPACITY) _start = 0;
      return SUCCESS;
    }
  }

  command error_t Reader.readChunk(uint8_t *buffer, uint16_t size){
    static uint16_t i;
    if (available() < size) {
      // Requested size is larger than what is available.
      return FAIL;
    }
    for (i = 0; i < size; i++) {
      buffer[i] = _buf[_start++];
      if (_start == CAPACITY) _start = 0;
    }
    return SUCCESS;
  }
  
  command void Writer.clear(){
    _start = 0;
    _end = 0;
  }

  command error_t Writer.write(uint8_t byte){
    if (_end + 1 == _start || (_start == 0 && _end + 1 == CAPACITY)) {
      return FAIL;
    }
    _buf[_end++] = byte;
    if (_end == CAPACITY) _end = 0;
    return SUCCESS;
  }

  command error_t Writer.writeChunk(uint8_t *buffer, uint16_t size){
    static uint16_t i;
    if (getFreeSpace() < size) {
      return FAIL;
    }
    for (i = 0; i < size; i++) {
      _buf[_end++] = buffer[i];
      if (_end == CAPACITY) _end = 0;
    }
    return SUCCESS;
  }

  command uint16_t Writer.getFreeSpace(){
    return getFreeSpace();
  }

  command void BlockReader.prepare(uint16_t imageWidth, uint8_t blockSize){
    _imageWidth = imageWidth;
    _blockSize = blockSize;
    _blocksPerRow = imageWidth / _blockSize;
    // BlockRowSize is the number of bytes required to fill a row of blocks
    _blockRowSize = _blockSize * _blockSize * _blocksPerRow;
    _blockIndex = 0;
  }
  
  command bool BlockReader.hasMoreBlocks(){
    return _blockIndex < available() / (_blockSize * _blockSize);
  }
  
  command void BlockReader.readNextBlock(uint8_t * outBuffer){
    uint16_t rowOffset, blockOffset, internalBufIdx, outBufferIndex = 0;
    uint8_t i, j;
    bool debug = TRUE;
    
    rowOffset = (_blockIndex / _blocksPerRow) * _blockRowSize;
    blockOffset = _blockIndex % _blocksPerRow;
    //debug = _blockIndex > 6;
//    
//    if (debug) {
//      printf("BlockSize: %u\n", _blockSize);
//      printf("blocksPerRow: %u\n", _blocksPerRow);
//      printf("BlockIndex: %u\n", _blockIndex);
//      printf("blockOffset: %u\n", blockOffset);
//      printf("rowOffset: %u\n", rowOffset);
//      printfflush();
//    }
//    if (debug) printf("\n");
    
    for (i = 0; i < _blockSize; i++) {
      for (j = 0; j < _blockSize; j++) {
        internalBufIdx = j + (_blockSize * blockOffset) + (_imageWidth * i) + rowOffset;
//        if (debug) printf("%u ", internalBufIdx);
        
        outBuffer[outBufferIndex] = _buf[internalBufIdx];
        outBufferIndex += 1;
        
        // Note: we increment _start variable only because we rely on the
        // available() method to determine when we have reach the end
        // of the buffer
        _start++;
        if (_start == CAPACITY) _start = 0;
      }
//      if (debug) printf("\n");
    }
    _blockIndex += 1;
    printfflush();
  }
}