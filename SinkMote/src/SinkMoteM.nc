#include "AM.h"
#include "Serial.h"
#include "PCFileSender.h"
#include "Messages.h"

module SinkMoteM @safe() {
  uses {
    interface Leds;
    interface PCFileSender;
    interface Boot;
    interface Timer<TMilli> as ErrorTimer;
    interface RadioReceiver;
  }
}
implementation{
  enum {
    MSG_QUEUE_CAPACITY = 10,
    BUFFER_CAPACITY = 4096,
    PAYLOAD_CAPACITY = 64,
    PC_SEND_CAPACITY = 50
  };
  
  uint8_t buffer[BUFFER_CAPACITY];
  uint16_t bufferHead;
  uint16_t bufferTail;
  uint16_t bufferCount;
  uint8_t lastSendBufferSize;
  bool pcBusy;
  
  task void sendNextDataToPC() {
    atomic {
      if (pcBusy == TRUE || bufferCount == 0) 
        return;

      pcBusy = TRUE;

      if (bufferCount > PC_SEND_CAPACITY) {
        lastSendBufferSize = PC_SEND_CAPACITY;
      } else {
        lastSendBufferSize = (uint8_t)bufferCount;
      }
      
      call PCFileSender.send(&(buffer[bufferHead]), lastSendBufferSize);
    }
  }

  event void Boot.booted(){
    bufferHead = 0;
    bufferTail = 0;
    pcBusy = FALSE;
    call PCFileSender.init();
  }
  
  event void PCFileSender.established(){
    call RadioReceiver.init();
  }
  
  event void RadioReceiver.initDone(){
    call Leds.led1Toggle();
  }

  event void RadioReceiver.receivedData(uint8_t *data, uint8_t size){
    uint8_t i;
    atomic {
      if (bufferCount + size > BUFFER_CAPACITY) {
        // We should not attempt to add items to the
        // buffer at this point. Signal an error.
        call Leds.led0On();
        return;
      }

      for (i = 0; i < size; i++) {
        buffer[bufferTail] = data[i];
        bufferTail = (bufferTail+1) % BUFFER_CAPACITY;
      }

      bufferCount = bufferCount + size;
    }
    
    post sendNextDataToPC();
  }

  event void PCFileSender.sent(){
    atomic {
      pcBusy = FALSE;
      bufferHead = (bufferHead + lastSendBufferSize) % BUFFER_CAPACITY;
      bufferCount = bufferCount - lastSendBufferSize;
    }
    if (bufferCount > 0) {
      post sendNextDataToPC();
    }
    call Leds.led2Toggle();
  }
  
  event void PCFileSender.error(PCFileSenderError error){
    switch (error) {
      case PFS_ERR_SEND_FAILED:
        call ErrorTimer.startPeriodic(100);
        break;
        
      case PFS_ERR_NOT_CONNECTED:
        call ErrorTimer.startPeriodic(1000);
        break;
        
      case PFS_ERR_MSG_PREPARATION_FAILED:
        call ErrorTimer.startPeriodic(5000);
        break;
    }
  }

  event void ErrorTimer.fired(){
    call Leds.led0Toggle();
  }

  event void RadioReceiver.error(RadioReceiverError error){
    call ErrorTimer.startPeriodic(500);
  }
}