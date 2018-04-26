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
  uint16_t blockIndex = 0;

  task void test() {
    uint8_t blockBuffer[16];
    uint16_t i;
    
    call BlockReader.readNextBlock(blockBuffer);
    
//    printf("BI: %u\n", blockIndex);
    
    if (blockIndex > 60) {
      for (i = 1; i < 17; i++) {
        printf("%u ", blockBuffer[i-1]);
        
        if (i % 4 == 0) {
          printf("\n");
        }
      }
      printf("\n");      
    }
    
    printfflush();
      
    if (call BlockReader.hasMoreBlocks()) {
      blockIndex++;
      post test();
    }
  }

  event void Boot.booted(){
    uint16_t i;
    uint8_t byte;
    error_t err;
    
    call Leds.set(0);
    call Leds.led1On();
    call BufferWriter.clear();
    
    for (i = 0; i < 1024; i++) {
      byte = (i+128) % 255;
      err = call BufferWriter.write(byte);
      if (err == FAIL) {
        printf("FAIL!\n");
        call Leds.led0On();
        return;
      }
    }
    
    call BlockReader.prepare(32, 4);
    
    post test();
    
    call Leds.led2On();
  }
}