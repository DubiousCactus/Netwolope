#include "printf.h"

module ProgramM{
  uses {
    interface Boot;
    interface Leds;
    interface PCFileReceiver;
    interface OnlineCompressionAlgorithm as Compressor;
    interface RadioSender as RadioSender;
    interface ErrorIndicator;
    interface Timer<TMilli> as Timer;
  }
}
implementation{
  uint8_t init = 0;

  event void Boot.booted(){
    call Timer.startPeriodic(1500);
    call Compressor.init();
  }

  event void Timer.fired() {
    uint8_t i;
    if (init) {
      uint8_t data[25] = {
        0x41, 0x42, 0x43, 0x44, 0x45,
        0x41, 0x42, 0x43, 0x44, 0x45,
        0x41, 0x42, 0x43, 0x44, 0x45,
        0x41, 0x42, 0x43, 0x44, 0x45,
        0x41, 0x42, 0x43, 0x44, 0x45
      };
      call Leds.led1Toggle();
      printf("\nFaking input buffer of size 25:\n");
      for (i = 0; i < 25; i++) {
        if (i % 5 == 0)
          printf("\n");

        printf("0x%02X ", data[i]);
      }

      printf("\n\n");
      printfflush();

      call Compressor.compress(data, 25);
      init = 0;
    }
  }
  
  event void Compressor.initDone() {
    /*call PCFileReceiver.init();*/
    printf("Compressor initialized !\n");
    init = 1;
    /*call RadioSender.init();*/
  }
  
  event void RadioSender.initDone(){
    call PCFileReceiver.init();
  }
  
  event void PCFileReceiver.initDone(){ 
     //call Leds.led1On();
  }
  
  event void PCFileReceiver.fileBegin(uint32_t totalLength){
    call Compressor.fileBegin(totalLength);
  }
  
  event void PCFileReceiver.receivedData(uint8_t *data, uint16_t length) {
    /*call Leds.led1On();*/
    printf("Received data over serial\nCompressing data...\n");
    call Compressor.compress(data, length);
  }
  
  event void PCFileReceiver.fileEnd(){
    call Compressor.fileEnd();
  }
  
  event void Compressor.compressed(uint8_t *compressedData, uint16_t length) {
    uint8_t i;
    call Leds.led2On();
    printf("Done compressing batch\n");
    printf("Compressed size: %d bytes\n", length);   
    for (i = 0; i < length; i++) {
        if (i % 5 == 0)
          printf("\n");

        printf("0x%02X ", compressedData[i]);
    }
    printf("\n\n");
    printfflush();

    /* call RadioSender.sendPartialData(compressedData, length); */
  }
  
  event void Compressor.compressDone() {
    /*call Leds.led2On();*/
    /*call RadioSender.sendEOF();*/
    printf("Compression done!");
  }

  event void RadioSender.sendDone(){
    call PCFileReceiver.receiveMore();
  }

  event void RadioSender.error(RadioSenderError error) {
    //call ErrorIndicator.blinkRed(error);
  }

  event void PCFileReceiver.error(PCFileReceiverError error){
    //call ErrorIndicator.blinkRed(error);
  }
  
  event void Compressor.error(CompressionError error) {
    call Leds.led0On();
  }
}
