#include "AM.h"
#include "Serial.h"
#include "PCFileSender.h"
#include "Messages.h"

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
    STATE_WAITING_START_RESPONSE,
    STATE_ESTABLISHED,
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
  
  message_t packet;
  uint8_t currentRetry = 0;
  ConnectionState state = STATE_BEGIN;
  
  void* prepareMsg(uint8_t msgSize) {
    void* msg = call SerialPacket.getPayload(&packet, msgSize);
    if (msg == NULL) {
      signal PCFileSender.error(PFS_ERR_MSG_PREPARATION_FAILED);
    }
    if (call SerialPacket.maxPayloadLength() < msgSize) {
      signal PCFileSender.error(PFS_ERR_MSG_PREPARATION_FAILED);
    }
    return msg;    
  }
  
  void sendPartialData(uint8_t *data, uint8_t size) {
    PartialDataMsg* msg = (PartialDataMsg*)prepareMsg(sizeof(PartialDataMsg));
    uint8_t i;
    
    msg->seqNo = 10;
    msg->flags = 1;
    msg->dataSize = size;
    for (i = 0; i < size; i++) {
      msg->data[i] = data[i];
    }
    
    if (call SerialSend.send[AM_MSG_PARTIAL_DATA](AM_BROADCAST_ADDR, &packet, sizeof(PartialDataMsg)) == SUCCESS) {
      atomic {
        state = STATE_SENDING_PARTIAL_DATA;
      }
    } else {
      signal PCFileSender.error(PFS_ERR_SEND_FAILED);
    }
  }
  
  void sendPartialDataMessage(message_t *msg, uint8_t msgSize) {
    if (call SerialSend.send[AM_MSG_PARTIAL_DATA](AM_BROADCAST_ADDR, msg, msgSize) == SUCCESS) {
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
  
  task void sendBeginFileMsg() {
    BeginFileMsg* msg = (BeginFileMsg*)prepareMsg(sizeof(BeginFileMsg));
    msg->type = 0; // TODO: Fix this by sending something meaningful
    
    if (call SerialSend.send[AM_MSG_BEGIN_FILE](AM_BROADCAST_ADDR, &packet, sizeof(BeginFileMsg)) == SUCCESS) {
      atomic {
        state = STATE_SENDING_START_REQUEST;
      }
    } else {
      signal PCFileSender.error(PFS_ERR_SEND_FAILED);
    }
  }
  
  task void startCommunicationTask() {
    atomic {
        currentRetry += 1;
    }
    post sendBeginFileMsg();
  }

  command void PCFileSender.init(){
    call SerialControl.start();
  }

  command void PCFileSender.send(uint8_t *data, uint8_t size){
    atomic {
      if (state == STATE_ESTABLISHED) {
        sendPartialData(data, size);
      } else {
        signal PCFileSender.error(PFS_ERR_NOT_CONNECTED);
      }
    }
  }

  command void PCFileSender.sendMessage(message_t *message, uint8_t payloadSize){
    atomic {
      if (state == STATE_ESTABLISHED) {
        sendPartialDataMessage(message, payloadSize);
      } else {
        signal PCFileSender.error(PFS_ERR_NOT_CONNECTED);
      }
    }
  }

  command void PCFileSender.sendEOF(){
    atomic {
      if (state == STATE_ESTABLISHED) {
        sendEOFMessage();
      } else {
        signal PCFileSender.error(PFS_ERR_NOT_CONNECTED);
      }
    }
  }
  
  /* REGION: Event handlers */

  event void SerialControl.startDone(error_t error){
    if (error == SUCCESS) {
      post startCommunicationTask();
    } else {
      signal PCFileSender.error(PFS_ERR_SEND_FAILED);
    }
  }

  event void SerialControl.stopDone(error_t error){ }

  event void Timeout.fired(){
    atomic {
      if (state == STATE_WAITING_START_RESPONSE) {
        // Timeout reach and we are still waiting for
        // a response from PC. Retry once more.
        post startCommunicationTask();
      }
    }
  }

  event void SerialSend.sendDone[am_id_t msg_type](message_t *msg, error_t error){
    if (error == SUCCESS) {
      atomic {
        if (state == STATE_SENDING_START_REQUEST) {
          // BeginTransmit Message has been sent to the PC
          // Now we are waiting for a response.
          state = STATE_WAITING_START_RESPONSE;
          
          // Wait 2 seconds before resending the
          // BeginTransmit message to the PC.
          call Timeout.startOneShot(2000);
          
        } else if (state == STATE_SENDING_PARTIAL_DATA) {
          // The data that we have sent the PC was
          // received successfully. We go back to a
          // previous state where client can send 
          // more data.
          state = STATE_ESTABLISHED;
          
          // Signal client that the SEND request
          // was fulfilled.
          signal PCFileSender.sent();
        }
      }
    } else {
      signal PCFileSender.error(PFS_ERR_SEND_FAILED);
    }
  }

  event message_t * SerialReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len){
    atomic {
      if (state == STATE_WAITING_START_RESPONSE) {
        
        if (msg_type == AM_MSG_BEGIN_FILE_ACK) {
          // We have received an ACK for the TransmitBegin message.
          // This means that we have established a connection to 
          // the PC.
          call Timeout.stop();
          
          state = STATE_ESTABLISHED;
          signal PCFileSender.established();
        }
      }
    }
    return msg;
  }
}