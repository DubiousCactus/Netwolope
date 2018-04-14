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
    PAYLOAD_CAPACITY = 64
  };

  event void Boot.booted(){
    call PCFileSender.init();
  }
  
  event void PCFileSender.established(){
    call RadioReceiver.start();
  }
  
  event void RadioReceiver.readyForReceive(){
    call Leds.led1Toggle();
  }

  event void RadioReceiver.receivedData(uint8_t *data, uint8_t size){
    call PCFileSender.send(data, size);
  }

  event void PCFileSender.sent(){
    call Leds.led2Toggle();
  }
  
  event void PCFileSender.error(PCFileSenderError error){
    call ErrorTimer.startPeriodic(250);
  }

  event void ErrorTimer.fired(){
    call Leds.led0Toggle();
  }
}