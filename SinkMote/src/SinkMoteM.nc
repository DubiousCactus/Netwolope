#include "AM.h"
#include "Serial.h"
#include "PCFileSender.h"

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

  event void Boot.booted(){
    call PCFileSender.init();
  }
  
  event void PCFileSender.initDone(){
    call RadioReceiver.init();
  }
  
  event void RadioReceiver.initDone(){
    call Leds.led1Toggle();
  }
  
  event void RadioReceiver.receivedFileBegin(uint32_t uncompressedSize, uint8_t compressionType){
    call PCFileSender.sendFileBegin(uncompressedSize, compressionType);
    call Leds.led1Toggle();
  }

  event void PCFileSender.beginFileSent(){
    call RadioReceiver.sendBeginFileAckMsg();
    call Leds.led1Toggle();
  }
  event void RadioReceiver.receivedData(uint8_t *data, uint8_t size){
    call PCFileSender.sendPartialData(data, size);
  }
  event void PCFileSender.partialDataSent(){
    call RadioReceiver.sendPartialDataAckMsg();
  }
  event void RadioReceiver.receivedEOF(){
    call PCFileSender.sendEOF();
    call RadioReceiver.sendEOFAckMsg();
  }
  
  event void PCFileSender.error(PCFileSenderError error){
    switch (error) {
      case PFS_ERR_SEND_FAILED:
        call ErrorTimer.startPeriodic(500);
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
    call ErrorTimer.startPeriodic(2000);
  }
}