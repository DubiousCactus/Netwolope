#include "AM.h"
#include "Serial.h"
#include "PCFileSender.h"

module PCFileSenderM{
  provides {
    interface PCFileSender;
  }

  uses {
    interface Timer<TMilli> as Timeout;
    
    interface SplitControl as SerialControl;
    interface Packet as SerialPacket;
    interface AMPacket as SerialAMPacket;
    interface AMSend as SerialSend[am_id_t msg_type];
    interface Receive as SerialReceive[am_id_t msg_type];
  }
}
implementation{
  typedef enum {
    STATE_BEGIN,
    STATE_SENDING_START_REQUEST,
    STATE_WAITING_BEGIN_FILE_ACK,
    STATE_READY,
    STATE_SENDING_PARTIAL_DATA
  } ConnectionState;
  
  enum {
    AM_MSG_BEGIN_FILE = 64,
    AM_MSG_BEGIN_FILE_ACK = 65,
    AM_MSG_PARTIAL_DATA = 66,
    AM_MSG_PARTIAL_DATA_ACK = 67, 
    AM_MSG_EOF = 68,
    AM_MSG_EOF_ACK = 69
  };
  

  enum {
    PARTIAL_DATA_CAPACITY = 60,
    PAYLOAD_CAPACITY = 64,
  };

  typedef nx_struct {
    nx_uint8_t compressionType;
    nx_uint32_t uncompressedSize;
  } BeginFileMsg;

  typedef nx_struct {
    nx_uint8_t data[PAYLOAD_CAPACITY];
  } PartialDataMsg;

  typedef nx_struct {
    nx_uint8_t name;
  } EndOfFileMsg;

  message_t packet;
  uint8_t currentRetry = 0;
  ConnectionState state = STATE_BEGIN;
  
  inline void* prepareMsg(uint8_t msgSize) {
    void* msg = call SerialPacket.getPayload(&packet, msgSize);
    if (msg == NULL) {
      signal PCFileSender.error(PFS_ERR_MSG_PREPARATION_FAILED);
    }
    if (call SerialPacket.maxPayloadLength() < msgSize) {
      signal PCFileSender.error(PFS_ERR_MSG_PREPARATION_FAILED);
    }
    return msg;    
  }
  
  inline void sendPartialData(uint8_t *data, uint8_t size) {
    PartialDataMsg* msg = (PartialDataMsg*)prepareMsg(sizeof(PartialDataMsg));
    uint8_t i;
    
    if (size > PAYLOAD_CAPACITY) {
      signal PCFileSender.error(PFS_ERR_SEND_FAILED);
      return;
    }
    
    for (i = 0; i < size; i++) {
      msg->data[i] = data[i];
    }
    
    if (call SerialSend.send[AM_MSG_PARTIAL_DATA](AM_BROADCAST_ADDR, &packet, size) == SUCCESS) {
      atomic {
        state = STATE_SENDING_PARTIAL_DATA;
      }
    } else {
      signal PCFileSender.error(PFS_ERR_SEND_FAILED);
    }
  }
  
  void sendEOFMessage() {
    EndOfFileMsg* msg = (EndOfFileMsg*)prepareMsg(sizeof(EndOfFileMsg));
    msg->name = 1; // TODO: Fix this by sending something meaningful
    
    if (call SerialSend.send[AM_MSG_EOF](AM_BROADCAST_ADDR, &packet, sizeof(EndOfFileMsg)) == SUCCESS) {
      atomic {
        state = STATE_SENDING_PARTIAL_DATA;
      }
    } else {
      signal PCFileSender.error(PFS_ERR_SEND_FAILED);
    }
  }

  command void PCFileSender.init(){
    call SerialControl.start();
  }
  
  command void PCFileSender.sendFileBegin(uint32_t uncompressedSize, uint8_t compressionType){
    BeginFileMsg* msg = (BeginFileMsg*)prepareMsg(sizeof(BeginFileMsg));
    msg->uncompressedSize = uncompressedSize;
    msg->compressionType = compressionType;
    
    if (call SerialSend.send[AM_MSG_BEGIN_FILE](AM_BROADCAST_ADDR, &packet, sizeof(BeginFileMsg)) == SUCCESS) {
      atomic {
        state = STATE_SENDING_START_REQUEST;
      }
    } else {
      signal PCFileSender.error(PFS_ERR_SEND_FAILED);
    }
  }

  command void PCFileSender.sendPartialData(uint8_t *data, uint8_t size){
    atomic {
      if (state == STATE_READY) {
        sendPartialData(data, size);
      } else {
        signal PCFileSender.error(PFS_ERR_NOT_CONNECTED);
      }
    }
  }

  command void PCFileSender.sendEOF(){
    atomic {
      if (state == STATE_READY) {
        sendEOFMessage();
      } else {
        signal PCFileSender.error(PFS_ERR_NOT_CONNECTED);
      }
    }
  }
  
  /* REGION: Event handlers */

  event void SerialControl.startDone(error_t error){
    if (error == SUCCESS) {
      signal PCFileSender.initDone();
    } else {
      signal PCFileSender.error(PFS_ERR_SEND_FAILED);
    }
  }

  event void SerialControl.stopDone(error_t error){ }

  event void Timeout.fired(){
    
  }

  event void SerialSend.sendDone[am_id_t msg_type](message_t *msg, error_t error){
    if (error == SUCCESS) {
      atomic {
        if (state == STATE_SENDING_START_REQUEST) {
          // BeginTransmit Message has been sent to the PC
          // Now we are waiting for a response.
          state = STATE_WAITING_BEGIN_FILE_ACK;
                    
        } else if (state == STATE_SENDING_PARTIAL_DATA) {
          // The data that we have sent the PC was
          // received successfully. We go back to a
          // previous state where client can send 
          // more data.
          state = STATE_READY;
          
          // Signal client that the SEND request
          // was fulfilled.
          signal PCFileSender.partialDataSent();
        }
      }
    } else {
      signal PCFileSender.error(PFS_ERR_SEND_FAILED);
    }
  }

  event message_t * SerialReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len){
    atomic {
      if (state == STATE_WAITING_BEGIN_FILE_ACK) {
        if (msg_type == AM_MSG_BEGIN_FILE_ACK) {
          state = STATE_READY;
          signal PCFileSender.beginFileSent();
        }
      }
    }
    return msg;
  }
}