#include "printf.h"

module Netwolope2M{
  provides interface OnlineCompressionAlgorithm as Compressor;
  uses interface CircularBufferWriter as OutBuffer;
  uses interface CircularBufferReader as InBuffer;
}
implementation{
  uint32_t counter;
  enum {
    BUFFER_SIZE = 8
  };  

  void compress(){
    uint16_t a1, b1, a2, b2;
    uint8_t counterA;
    uint8_t hex1, i;
    uint8_t data[BUFFER_SIZE];
    uint16_t mean1, mean2;
    
    bool debug = counter > 3000;

    while (call InBuffer.available() > 3) {
      call InBuffer.readChunk(data, BUFFER_SIZE);
      
      a1 = 0;
      a2 = 0;
      b1 = 0;
      b2 = 0;
      counterA = 0;
      
      mean1 = (data[0] + data[1] + data[2] + data[3]) >> 2;
      mean2 = (data[4] + data[5] + data[6] + data[7]) >> 2;
      hex1 = 0;
      
      for (i = 0; i < 4; i++) {
        if (data[i] >= mean1)
        {
            hex1 = hex1 | 1 << (7-i);
            a1 = a1 + data[i];
            counterA++;
            //  hex1 = hex1 & ~(1 << (7-i));
        }else{
          b1 = b1 + data[i];
        }
        if (debug) {
            printf(" > Hex: %u  i=%u   a1=%u   b1=%u\n", hex1, i, a1, b1);
        }
      }
      
      if (counterA != 0)
        a1 = a1 / counterA;
      if (counterA != 4)
        b1 = b1 / (4 - counterA);
      
      counterA = 0;
      
      for (i = 4; i < 8; i++) {
        if (data[i] >= mean2) {
            hex1 = hex1 | 1 << (7-i);
            a2 = a2 + data[i];
            counterA++;
            // hex1 = hex1 & ~(1 << (7-i));
        } else {
          b2 = b2 + data[i];
        }
        if (debug) {
          printf(" > Hex: %u   i=%u   a2=%u   b2=%u \n", hex1, i, a2, b2);
        }
      }
      
      if (counterA != 0)
        a2 = a2 / counterA;
      if (counterA != 4)
        b2 = b2 / (4 - counterA);
      
      if (debug) {
        printf("Hex: %u Mean1: %u Mean2: %u   a1=%u   b1=%u   a2=%u   b2=%u  \n", hex1, mean1, mean2, a1, b1, a2, b2);
        printfflush();
      }
      
      call OutBuffer.write(hex1);
      call OutBuffer.write(a1);
      call OutBuffer.write(b1);
      call OutBuffer.write(a2);
      call OutBuffer.write(b2);
      
      counter += BUFFER_SIZE;
    }
  }

  command void Compressor.fileBegin(uint16_t imageWidth){  }

  command void Compressor.compress(bool last){
    compress();   
    signal Compressor.compressed();
  }
  
  command uint8_t Compressor.getCompressionType(){
    return COMPRESSION_TYPE_NETWOLOPE2;
  }
}