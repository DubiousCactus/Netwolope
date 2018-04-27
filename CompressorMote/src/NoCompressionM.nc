#include "OnlineCompressionAlgorithm.h"
#include "printf.h"

module NoCompressionM {
  provides interface OnlineCompressionAlgorithm;
  uses {
    interface CircularBufferReader as InBuffer;
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
    call BlockReader.readNextBlock(blockBuffer);   
    call OutBuffer.writeChunk(blockBuffer, 16);
  }

  command void OnlineCompressionAlgorithm.fileBegin(uint16_t imageWidth) {
    counter=0;
    call OutBuffer.clear();
    call BlockReader.prepare(imageWidth, 4);
    
  }
  
  command void OnlineCompressionAlgorithm.compress(bool last) {
    counter = 0;
    
    printf("Avail Before %u\n", call InBuffer.available());

      while (call BlockReader.hasMoreBlocks()) {
        sendNextBlock();
        counter++;
      }
    
    printf("Avail After %u\n", call InBuffer.available());
    
    printf("# hasMoreBlocks() calls %u\n", counter);
    printfflush();
    signal OnlineCompressionAlgorithm.compressed();
  }

  command uint8_t OnlineCompressionAlgorithm.getCompressionType() {
    return COMPRESSION_TYPE_NONE;
  }
}
