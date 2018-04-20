#include "RadioSender2.h"

module RadioSender2M{
  provides interface RadioSender2;
  
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
    BUFFER_CAPACITY = 128,
    PACKET_CAPACITY = 64
  };
  
  typedef enum {
    STATE_NOT_READY,
    STATE_READY,
    STATE_SENDING_PARTIAL_DATA,
    STATE_SENDING_EOF,
    STATE_WAITING_PARTIAL_DATA_ACK,
    STATE_WAITING_EOF_ACK
  } State;
  
  State currentState = STATE_NOT_READY;
  
  typedef nx_struct {
    nx_uint32_t totalSize;
    nx_uint8_t compressionType;
  } BeginFileMsg;
  
  typedef nx_struct {
    nx_uint32_t length;
  } AckMsg;
  
  typedef nx_struct {
    nx_uint8_t data[PACKET_CAPACITY];
  } PartialDataMsg;
  
  
  uint8_t *dataToSend;
  uint16_t dataToSendLength;
  uint16_t sendIndex;
  uint16_t newSendIndex;
  message_t pkt;
  
  void sendDataOverRadio(am_id_t msg_type, uint8_t* buffer, uint8_t bufferSize) {
    uint8_t i;
    PartialDataMsg* msg = (PartialDataMsg*)(call Packet.getPayload(&pkt, sizeof(PartialDataMsg)));
    if (bufferSize > PACKET_CAPACITY) {
      signal RadioSender2.error(RS_ERR_PROGRAMMER);
      return;
    }
    for (i = 0; i < bufferSize; i++) {
      msg->data[i] = buffer[i];
    }
    if (call RadioSend.send[msg_type](AM_BROADCAST_ADDR, &pkt, bufferSize) != SUCCESS) {
      signal RadioSender2.error(RS_ERR_SEND_FAILED);
    }
  }
  
  task void sendNextPacketOverRadio() {
    uint8_t bufferSize;
    atomic {
      if (sendIndex == dataToSendLength){
        signal RadioSender2.error(RS_ERR_INIT_FAILED);
        return;
      }
      currentState = STATE_SENDING_PARTIAL_DATA;
      if (sendIndex + PACKET_CAPACITY > dataToSendLength) {
        bufferSize = (uint8_t)(dataToSendLength - sendIndex);
      } else {
        bufferSize = PACKET_CAPACITY;
      }
      newSendIndex = sendIndex + bufferSize;
      sendDataOverRadio(AM_MSG_PARTIAL_DATA, &(dataToSend[sendIndex]), bufferSize);
    }
  }

  command void RadioSender2.init(){
    call RadioControl.start();
  }

  command void RadioSender2.sendPartialData(uint8_t *buffer, uint16_t bufferSize){
    atomic {
      if (currentState != STATE_READY) {
        signal RadioSender2.error(RS_ERR_INVALID_STATE);
        return;
      }
      
      dataToSend = buffer;
      dataToSendLength = bufferSize;
      sendIndex = 0;
    }
    
    post sendNextPacketOverRadio();
  }

  command void RadioSender2.sendEOF(){
    atomic {
      if (currentState != STATE_READY) {
        signal RadioSender2.error(RS_ERR_INVALID_STATE);
        return;
      }
      
      currentState = STATE_SENDING_EOF;
      if (call RadioSend.send[AM_MSG_EOF](AM_BROADCAST_ADDR, &pkt, 0) != SUCCESS) {
        signal RadioSender2.error(RS_ERR_SEND_FAILED);
      }
    }
  }
  
  event void RadioControl.startDone(error_t error){
    if (error == SUCCESS) {
      currentState = STATE_READY;
      signal RadioSender2.initDone();
    } else {
      signal RadioSender2.error(RS_ERR_INIT_FAILED);
    }
  }

  event void RadioControl.stopDone(error_t error){
    // TODO Auto-generated method stub
  }

  event void RadioSend.sendDone[am_id_t msg_type](message_t *msg, error_t error){
    if (error != SUCCESS) {
      signal RadioSender2.error(RS_ERR_SEND_FAILED);
      return;
    }
    
    atomic {
      if (currentState == STATE_SENDING_PARTIAL_DATA) {
        currentState = STATE_WAITING_PARTIAL_DATA_ACK;
      } else if (currentState == STATE_SENDING_EOF) {
        currentState = STATE_WAITING_EOF_ACK;
      } else {
        signal RadioSender2.error(RS_ERR_INVALID_STATE);
      }
    }
  }

  event message_t * RadioReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len){
    atomic {
      if (currentState == STATE_WAITING_PARTIAL_DATA_ACK) {
        if (msg_type == AM_MSG_ACK_PARTIAL_DATA) {
          sendIndex = newSendIndex;
          if (sendIndex < dataToSendLength) {
            post sendNextPacketOverRadio();
          } else {
            currentState = STATE_READY;
            signal RadioSender2.sendDone();
          }   
        }
      } else if (currentState == STATE_WAITING_EOF_ACK){
        // TODO: Do something here
        currentState = STATE_READY;
      } else {
        signal RadioSender2.error(RS_ERR_INVALID_STATE);
      }
    }
    return msg;
  }
}