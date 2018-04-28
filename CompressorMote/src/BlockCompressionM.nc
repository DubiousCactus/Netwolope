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
  uint16_t _blockNo; 
  
  inline void sendNextBlock() {
    uint8_t blockBuffer[16];
    uint16_t i;
    
    call BlockReader.readNextBlock(blockBuffer); 
    
    if (_blockNo == 63 || _blockNo == 64 || _blockNo == 65) {
      printf("Block %u\n", _blockNo);
      for (i = 1; i < 17; i++) {
        printf("%u ", blockBuffer[i-1]);
        if (i%4 == 0) {
          printf("\n");
        }
      }
    }
      
    call OutBuffer.writeChunk(blockBuffer, 16);
    _blockNo += 1;
  }

  command void OnlineCompressionAlgorithm.fileBegin(uint16_t imageWidth) {
    call OutBuffer.clear();
    call BlockReader.prepare(imageWidth, 4);
    _blockNo = 1;
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
