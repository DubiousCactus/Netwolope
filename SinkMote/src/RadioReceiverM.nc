#include "RadioHeader.h"
#include "Timer.h"
module RadioReceiverM{
  provides interface RadioReceiver;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend as RadioSend[am_id_t msg_type];
  uses interface Receive as RadioReceive[am_id_t msg_type];
  uses interface SplitControl as RadioControl;
  
}
implementation{
  enum {
    AM_MSG_PARTIAL_DATA       = 22,
    AM_MSG_ACK_PARTIAL_DATA   = 23,
    AM_MSG_EOF                = 24,
    AM_MSG_ACK_EOF            = 25,
  };
  
  message_t pkt;
  
  void sendPartialDataAckMsg() {
    if (call RadioSend.send[AM_MSG_ACK_PARTIAL_DATA](AM_BROADCAST_ADDR, &pkt, 0) != SUCCESS) {
      signal RadioReceiver.error(RR_ERR_SEND_FAILED);
    }
  }
  
  void sendEOFAckMsg() {
    if (call RadioSend.send[AM_MSG_ACK_EOF](AM_BROADCAST_ADDR, &pkt, 0) != SUCCESS) {
      signal RadioReceiver.error(RR_ERR_SEND_FAILED);
    }
  }
  
  command void RadioReceiver.init(){
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t error){
    signal RadioReceiver.initDone();
  }

  event void RadioControl.stopDone(error_t error){ }

  event void RadioSend.sendDone[am_id_t msg_type](message_t *msg, error_t error){
    if (error != SUCCESS) {
      signal RadioReceiver.error(RR_ERR_SEND_FAILED);
    }
  }

  event message_t * RadioReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len){
    if (msg_type == AM_MSG_PARTIAL_DATA) {
      signal RadioReceiver.receivedData((uint8_t*)payload, len);
      sendPartialDataAckMsg();
    } else if (msg_type == AM_MSG_EOF) {
      signal RadioReceiver.receivedEOF();
      sendEOFAckMsg();
    }
    return msg;
  }
}