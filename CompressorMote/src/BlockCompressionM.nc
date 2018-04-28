#include "OnlineCompressionAlgorithm.h"
#include "printf.h"

module BlockCompressionM {
  provides interface OnlineCompressionAlgorithm;
  uses {
    interface CircularBufferReader as InBuffer;
    interface CircularBufferWriter as OutBuffer;
    interface CircularBufferBlockReader as BlockReader;
  }
}
implementation {
  enum {
    BLOCK_SIZE = 4,
    BUFFER_SIZE = 16
  }; 
  
  inline void sendNextBlock() {
    uint8_t blockBuffer[BUFFER_SIZE];
    
    call BlockReader.readNextBlock(blockBuffer); 
    call OutBuffer.writeChunk(blockBuffer, BUFFER_SIZE);
  }

  command void OnlineCompressionAlgorithm.fileBegin(uint16_t imageWidth) {
    call OutBuffer.clear();
    call BlockReader.prepare(imageWidth, BLOCK_SIZE);
  }
  
  command void OnlineCompressionAlgorithm.compress(bool last) {
    while (call BlockReader.hasMoreBlocks()) {
      sendNextBlock();
    }
    signal OnlineCompressionAlgorithm.compressed();
  }

  command uint8_t OnlineCompressionAlgorithm.getCompressionType() {
    return COMPRESSION_TYPE_BLOCK;
  }
}
