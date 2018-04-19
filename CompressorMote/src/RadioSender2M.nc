#include "RadioSender2.h"

module RadioSender2M{
  provides interface RadioSender2;
  
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as RadioControl;
}
implementation{

  command void RadioSender2.init(){
    call RadioControl.start();
  }
  
  event void RadioControl.startDone(error_t error){
    if (error == SUCCESS) {
      signal RadioSender2.initDone();
    } else {
      signal RadioSender2.error(RS_ERR_INIT_FAILED);
    }
  }

  command void RadioSender2.sendPartialData(uint8_t *buffer, uint16_t bufferSize){
    // TODO Auto-generated method stub
  }

  command void RadioSender2.sendEOF(){
    // TODO Auto-generated method stub
  }

  event void RadioControl.stopDone(error_t error){
    // TODO Auto-generated method stub
  }

  event void AMSend.sendDone(message_t *msg, error_t error){
    // TODO Auto-generated method stub
  }

  event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
    return msg;
  }
}