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
    AM_MSG_BEGIN_FILE         = 20,
    AM_MSG_ACK_BEGIN_FILE     = 21,
    AM_MSG_PARTIAL_DATA       = 22,
    AM_MSG_ACK_PARTIAL_DATA   = 23,
    AM_MSG_EOF                = 24,
    AM_MSG_ACK_EOF            = 25,
  };
  
  typedef nx_struct {
    nx_uint32_t uncompressedSize;
    nx_uint8_t compressionType;
  } BeginFileMsg;
  
  message_t pkt;
  
  task void sendPartialDataAckMsg() {
    if (call RadioSend.send[AM_MSG_ACK_PARTIAL_DATA](AM_BROADCAST_ADDR, &pkt, 0) != SUCCESS) {
      post sendPartialDataAckMsg();
    }
  }
  
  task void sendEOFAckMsg() {
    if (call RadioSend.send[AM_MSG_ACK_EOF](AM_BROADCAST_ADDR, &pkt, 0) != SUCCESS) {
      post sendEOFAckMsg();
    }
  }
  
  task void sendBeginFileAckMsg() {
    if (call RadioSend.send[AM_MSG_ACK_BEGIN_FILE](AM_BROADCAST_ADDR, &pkt, 0) != SUCCESS) {
      post sendBeginFileAckMsg();
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
    if (msg_type == AM_MSG_BEGIN_FILE) {
      BeginFileMsg* msg = (BeginFileMsg*)payload;
      signal RadioReceiver.receivedFileBegin(msg->uncompressedSize, msg->compressionType);
      
    } else if (msg_type == AM_MSG_PARTIAL_DATA) {
      signal RadioReceiver.receivedData((uint8_t*)payload, len);
    
    } else if (msg_type == AM_MSG_EOF) {
      signal RadioReceiver.receivedEOF();
    }
    return msg;
  }

  command void RadioReceiver.sendEOFAckMsg(){
    post sendEOFAckMsg();
  }

  command void RadioReceiver.sendBeginFileAckMsg(){
    post sendBeginFileAckMsg();
  }

  command void RadioReceiver.sendPartialDataAckMsg(){
    post sendPartialDataAckMsg();
  }
}