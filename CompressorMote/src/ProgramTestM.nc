#include "printf.h"

module ProgramTestM{
  uses {
    interface Boot;
    interface Leds;
    interface CircularBufferReader as BufferReader;
    interface CircularBufferWriter as BufferWriter;
    interface CircularBufferBlockReader as BlockReader;
  }
}
implementation{

  event void Boot.booted(){
    uint16_t i;
    uint8_t byte;
    uint8_t blockBuffer[16];
    uint8_t y;
    
    call Leds.set(0);
    
    call BufferWriter.clear();
    
    for (i = 0; i < 1024; i++) {
      byte = (i+128) % 255;
      call BufferWriter.write(byte);
    }
    
    call BlockReader.prepare(32, 4);
    
    
    while (call BlockReader.hasMoreBlocks()) {
      call BlockReader.readNextBlock(blockBuffer);
      
      for (i = 1; i < 17; i++) {
        printf("%u ", blockBuffer[i-1]);
        
        if (i % 4 == 0) {
          printf("\n");
        }
      }
      
      printf("\n");
      printfflush();
    }
    
    call Leds.led1On();
    
  }
}