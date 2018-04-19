#include "OnlineCompressionAlgorithm.h"

module NoCompressionM {
  provides interface OnlineCompressionAlgorithm;
}
implementation {

  command void OnlineCompressionAlgorithm.init() {
    signal OnlineCompressionAlgorithm.initDone();
  }
  
  command void OnlineCompressionAlgorithm.fileBegin(uint32_t totalLength) {
    // Ignore
  }
  
  command void OnlineCompressionAlgorithm.compress(uint8_t *data, uint16_t length) {
    signal OnlineCompressionAlgorithm.compressed(data, length);
  }

  command void OnlineCompressionAlgorithm.fileEnd() {
    signal OnlineCompressionAlgorithm.compressDone();
  }

  command uint8_t OnlineCompressionAlgorithm.getCompressionType() {
    return COMPRESSION_TYPE_NONE;
  }
}
