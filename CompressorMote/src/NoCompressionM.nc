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
        call InBuffer.read(&byte);
        call OutBuffer.write(byte);
      }
    
    signal OnlineCompressionAlgorithm.compressed();
  }

  command uint8_t OnlineCompressionAlgorithm.getCompressionType(){
    return COMPRESSION_TYPE_NONE;
  }
}