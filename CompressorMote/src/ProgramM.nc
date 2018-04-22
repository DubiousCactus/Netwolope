#include "printf.h"

module ProgramM{
  uses {
    interface Boot;
    interface Leds;
    interface PCFileReceiver;
    interface OnlineCompressionAlgorithm as Compressor;
    interface RadioSender;
    interface ErrorIndicator;
    interface Timer<TMilli> as Timer;
  }
}
implementation{
  enum {
    RADIO_DATA_CAPACITY = 50
  };
  
  uint8_t temp[RADIO_DATA_CAPACITY];
  uint8_t *dataToSend;
  uint8_t init = 0;
  uint16_t dataToSendLength;
  uint16_t sendIndex;
  uint16_t newSendIndex;
  
  task void sendNextPacketOverRadio() {
    uint8_t bufferSize;
    atomic {
      if (sendIndex == dataToSendLength) {
        // All data are sent over the radio. 
        call ErrorIndicator.blinkRed(7);
        return;
      }
      if (sendIndex + RADIO_DATA_CAPACITY > dataToSendLength) {
        bufferSize = (uint8_t)(dataToSendLength - sendIndex);
      } else {
        bufferSize = RADIO_DATA_CAPACITY;
      }
      call Leds.led2Off();
      newSendIndex = sendIndex + bufferSize;
      call RadioSender.send(0, 0, &(dataToSend[sendIndex]), bufferSize);
    }
  }
  
  // EVENT HANDLERS
  
  event void Boot.booted() {
    dataToSendLength = 0;
    sendIndex = 0;
    call Timer.startPeriodic(1500);
    call Compressor.init();
  }

  event void Timer.fired() {
    uint8_t i;
    printf("\nTimer fired\n");
    if (init) {
      uint8_t data[25] = {
        0x41, 0x42, 0x43, 0x44, 0x45,
        0x41, 0x42, 0x43, 0x44, 0x45,
        0x41, 0x42, 0x43, 0x44, 0x45,
        0x41, 0x42, 0x43, 0x44, 0x45,
        0x41, 0x42, 0x43, 0x44, 0x45
      };
      call Leds.led1Toggle();
      printf("\nFaking input buffer:\n");
      for (i = 0; i < 25; i++) {
        if (i % 5 == 0)
          printf("\n");

        printf("0x%X ", data[i]);
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
    /*call RadioSender.start();*/
  }
  
  event void RadioSender.readyToSend() {
    call PCFileReceiver.init();
    /*call Leds.led1Toggle();*/
  }
  
  event void PCFileReceiver.initDone() { 
  }
  
  event void PCFileReceiver.fileBegin(uint32_t totalLength) {
    call Compressor.fileBegin(totalLength);
  }
  
  event void PCFileReceiver.receivedData(uint8_t *data, uint16_t length) {
    /*call Leds.led1On();*/
    printf("Received data over serial\nCompressing data...\n");
    call Compressor.compress(data, length);
  }
  
  event void PCFileReceiver.fileEnd() {
    call Compressor.fileEnd();
  }
  
  event void Compressor.compressed(uint8_t *compressedData, uint16_t length) {
    uint8_t i;
    atomic {
      dataToSend = compressedData;
      dataToSendLength = length;
      sendIndex = 0;
    }
    call Leds.led2On();
    printf("Done compressing batch\n");
    printf("Compressed %d bytes\n", length);   
    for (i = 0; i < length; i++) {
        if (i % 5 == 0)
          printf("\n");

        printf("%X ", compressedData[i]);
    }


    /*post sendNextPacketOverRadio();*/
  }
  
  event void Compressor.compressDone() {
    /*call Leds.led2On();*/
    /*call RadioSender.send(1, 0, temp, 0);*/
    printf("Compression done!");
  }

  event void RadioSender.sendDone() {
    /*call Leds.led2On();*/
    atomic {
      sendIndex = newSendIndex;
      if (sendIndex < dataToSendLength) {
        post sendNextPacketOverRadio();
      } else {
        call PCFileReceiver.receiveMore();
      }      
    }
  }

  event void PCFileReceiver.error(PCFileReceiverError error) {
    call ErrorIndicator.blinkRed(error);
  }
  
  event void Compressor.error(CompressionError error) {
    call Leds.led0On();
  }
}
