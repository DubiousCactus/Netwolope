#include "printf.h"
#include <math.h>

module NetwolopeAlgorithmM{
  provides interface OnlineCompressionAlgorithm as Compressor;
  uses interface CircularBufferWriter as OutBuffer;
  uses interface CircularBufferReader as InBuffer;
}
implementation{
  uint8_t _result;

  void compress(){
    uint8_t data1, data2;

    while (call InBuffer.available() > 1) {
      call InBuffer.read(&data1);
      call InBuffer.read(&data2);

      _result = (data1 >> 4) << 4 | (data2 >> 4);
      call OutBuffer.write(_result);
    }
  }

  command void Compressor.fileBegin(uint16_t imageWidth){  }

  command void Compressor.compress(bool last){
    compress();   
    signal Compressor.compressed();
  }
  
  command uint8_t Compressor.getCompressionType(){
    return COMPRESSION_TYPE_NETWOLOPE;
  }
}