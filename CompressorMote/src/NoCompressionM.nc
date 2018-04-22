#include "OnlineCompressionAlgorithm.h"

module NoCompressionM{
  provides interface OnlineCompressionAlgorithm;
  uses {
    interface CircularBufferReader as InBuffer;
    interface CircularBufferWriter as OutBuffer;
  }
}
implementation{
  enum {
    BLOCK_SIZE = 64
  };

  command void OnlineCompressionAlgorithm.fileBegin(uint32_t totalLength){
    call OutBuffer.clear();
  }
  
  command void OnlineCompressionAlgorithm.compress(bool last){
    uint8_t byte;

      while (call InBuffer.available() > 0) {
        if (call InBuffer.read(&byte) == SUCCESS) {
          if (call OutBuffer.write(byte) != SUCCESS) 
            signal OnlineCompressionAlgorithm.error(1);          
        } else {
          signal OnlineCompressionAlgorithm.error(2);
          break;
        }
      }
    
    signal OnlineCompressionAlgorithm.compressed();
  }

  command uint8_t OnlineCompressionAlgorithm.getCompressionType(){
    return COMPRESSION_TYPE_NONE;
  }
}