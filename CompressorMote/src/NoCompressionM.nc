#include "OnlineCompressionAlgorithm.h"
#include "printf.h"

module NoCompressionM {
  provides interface OnlineCompressionAlgorithm;
  uses {
//    interface CircularBufferReader as InBuffer;
    interface CircularBufferWriter as OutBuffer;
    interface CircularBufferBlockReader as BlockReader;
  }
}
implementation {
  enum {
    BLOCK_SIZE = 64
  };
  uint16_t counter; 
  inline void sendNextBlock() {
    uint8_t blockBuffer[16];
//    uint16_t i;
    
    call BlockReader.readNextBlock(blockBuffer);
    
//    for (i = 0; i < 16; i++) {
//      printf("%u ", blockBuffer[i]);
//    }
//    printf("\n");
    
    call OutBuffer.writeChunk(blockBuffer, 16);
  }

  command void OnlineCompressionAlgorithm.fileBegin(uint16_t imageWidth) {
    counter=0;
    call OutBuffer.clear();
    call BlockReader.prepare(imageWidth, 4);
    
  }
  
  command void OnlineCompressionAlgorithm.compress(bool last) {
    counter++;
//    printf("Start\n");
    
      while (call BlockReader.hasMoreBlocks()) {
        sendNextBlock();
      }
    
    printf("Counter: %u\n", counter);
    printfflush();
    signal OnlineCompressionAlgorithm.compressed();
  }

  command uint8_t OnlineCompressionAlgorithm.getCompressionType() {
    return COMPRESSION_TYPE_NONE;
  }
}
