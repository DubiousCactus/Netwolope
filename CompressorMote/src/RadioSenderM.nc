#include "RadioSender.h"

module RadioSenderM{
  provides interface RadioSender;
  
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend as RadioSend[am_id_t msg_type];
  uses interface Receive as RadioReceive[am_id_t msg_type];
  uses interface SplitControl as RadioControl;
  uses interface CircularBufferReader as Reader;
}
implementation{
  enum {
    AM_MSG_BEGIN_FILE         = 20,
    AM_MSG_ACK_BEGIN_FILE     = 21,
    AM_MSG_PARTIAL_DATA       = 22,
    AM_MSG_ACK_PARTIAL_DATA   = 23,
    AM_MSG_EOF                = 24,
    AM_MSG_ACK_EOF            = 25,
    
    BUFFER_CAPACITY = 128,
    PACKET_CAPACITY = 64
  };
  
  typedef enum {
    STATE_NOT_READY = 2,
    STATE_READY,
    STATE_SENDING_BEGIN_FILE,
    STATE_SENDING_PARTIAL_DATA,
    STATE_SENDING_EOF,
    STATE_WAITING_PARTIAL_DATA_ACK,
    STATE_WAITING_EOF_ACK,
    STATE_WAITING_BEGIN_FILE_ACK
  } State;
  
  State currentState = STATE_NOT_READY;
  
  typedef nx_struct {
    nx_uint32_t uncompressedSize;
    nx_uint8_t compressionType;
  } BeginFileMsg;
  
  typedef nx_struct {
    nx_uint32_t length;
  } AckMsg;
  
  typedef nx_struct {
    nx_uint8_t data[PACKET_CAPACITY];
  } PartialDataMsg;
  
  message_t pkt;


  command void RadioSender.init(){
    call RadioControl.start();
  }

  command void RadioSender.sendFileBegin(uint32_t uncompressedSize, uint8_t compressionType){
    BeginFileMsg* msg = (BeginFileMsg*)(call Packet.getPayload(&pkt, sizeof(BeginFileMsg)));
    msg->uncompressedSize = uncompressedSize;
    msg->compressionType = compressionType;
    currentState = STATE_SENDING_BEGIN_FILE;
    if (call RadioSend.send[AM_MSG_BEGIN_FILE](AM_BROADCAST_ADDR, &pkt, sizeof(BeginFileMsg)) != SUCCESS) {
      signal RadioSender.error(RS_ERR_SEND_FAILED);
    }
  }

  command bool RadioSender.canSend(){
    return (call Reader.available() > 0);
  }

  command bool RadioSender.canSendFullPacket(){
    return (call Reader.available() >= PACKET_CAPACITY);
  }

  command void RadioSender.sendPartialData(){
    uint8_t transferSize = 0;
    uint16_t availableBytes = 0;
    PartialDataMsg* msg;
    
    if (currentState != STATE_READY) {
      signal RadioSender.error(RS_ERR_INVALID_STATE);
      return;
    }
    
    availableBytes = call Reader.available();
    if (availableBytes > 0) {
      if (availableBytes > PACKET_CAPACITY) {
        transferSize = PACKET_CAPACITY;
      } else {
        transferSize = availableBytes;
      }
      
      msg = (PartialDataMsg*)(call Packet.getPayload(&pkt, sizeof(PartialDataMsg)));
      if (call Reader.readChunk((uint8_t*)msg->data, (uint16_t)transferSize) != SUCCESS) {
        signal RadioSender.error(RS_ERR_PROGRAMMER);
        return;
      }
      
      currentState = STATE_SENDING_PARTIAL_DATA;
      if (call RadioSend.send[AM_MSG_PARTIAL_DATA](AM_BROADCAST_ADDR, &pkt, transferSize) != SUCCESS) {
        signal RadioSender.error(RS_ERR_SEND_FAILED);
      }
    } else {
      signal RadioSender.sendDone();
    }
  }

  command void RadioSender.sendEOF(){
    atomic {
      if (currentState != STATE_READY) {
        signal RadioSender.error(RS_ERR_INVALID_STATE);
        return;
      }
      
      currentState = STATE_SENDING_EOF;
      if (call RadioSend.send[AM_MSG_EOF](AM_BROADCAST_ADDR, &pkt, 0) != SUCCESS) {
        signal RadioSender.error(RS_ERR_SEND_FAILED);
      }
    }
  }
  
  event void RadioControl.startDone(error_t error){
    if (error == SUCCESS) {
      currentState = STATE_READY;
      signal RadioSender.initDone();
    } else {
      signal RadioSender.error(RS_ERR_INIT_FAILED);
    }
  }

  event void RadioControl.stopDone(error_t error){
    // TODO Auto-generated method stub
  }

  event void RadioSend.sendDone[am_id_t msg_type](message_t *msg, error_t error){
    if (error != SUCCESS) {
      signal RadioSender.error(RS_ERR_SEND_FAILED);
      return;
    }
    
    atomic {
      if (currentState == STATE_SENDING_PARTIAL_DATA) {
        currentState = STATE_WAITING_PARTIAL_DATA_ACK;
      } else if (currentState == STATE_SENDING_EOF) {
        currentState = STATE_WAITING_EOF_ACK;
      } else if (currentState == STATE_SENDING_BEGIN_FILE) {
        currentState = STATE_WAITING_BEGIN_FILE_ACK;
      } else {
        signal RadioSender.error(RS_ERR_INVALID_STATE);
      }
    }
  }

  event message_t * RadioReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len){
    atomic {
      if (currentState == STATE_WAITING_PARTIAL_DATA_ACK) {
        if (msg_type == AM_MSG_ACK_PARTIAL_DATA) {
          currentState = STATE_READY;
          signal RadioSender.sendDone();
        }
      } else if (currentState == STATE_WAITING_EOF_ACK){
        // TODO: Do something here
        currentState = STATE_READY;
      } else if (currentState == STATE_WAITING_BEGIN_FILE_ACK){
        // TODO: Do something here
        currentState = STATE_READY;
        signal RadioSender.fileBeginAcknowledged();
      } else {
        signal RadioSender.error(RS_ERR_INVALID_STATE);
      }
    }
    return msg;
  }
}
