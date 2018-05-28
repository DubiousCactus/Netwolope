#include "OnlineCompressionAlgorithm.h"

module NoCompressionM {
  provides interface OnlineCompressionAlgorithm;
  uses interface CircularBufferReader as InBuffer;
  uses interface CircularBufferWriter as OutBuffer;
}
implementation {
  command void OnlineCompressionAlgorithm.fileBegin(uint16_t imageWidth) {
    call OutBuffer.clear();
  }
  
  command void OnlineCompressionAlgorithm.compress(bool last) {
    uint8_t byte;

    while (call InBuffer.available() > 0) {
      call InBuffer.read(&byte);
      call OutBuffer.write(byte);
    }
    
    signal OnlineCompressionAlgorithm.compressed();
  }

  command uint8_t OnlineCompressionAlgorithm.getCompressionType() {
    return COMPRESSION_TYPE_NONE;
  }
}
