
#include "AM.h"
#include "Serial.h"
#include "PCComm.h"

module PCCom{
  provides {
    interface PCConnection;
  }

  uses {
    interface Leds;
    interface Timer<TMilli> as ErrorTimer;
    interface Timer<TMilli> as Timeout;
    
    interface SplitControl as SerialControl;
    interface Packet as SerialPacket;
    interface AMPacket as SerialAMPacket;
    interface AMSend as SerialSend[am_id_t msg_type];
    interface Receive as SerialReceive[am_id_t msg_type];
  }
}
implementation{
  message_t packet;
  uint8_t currentRetry = 0;
  ConnectionState state = STATE_BEGIN;
  
  void signalPacketDropped() {
    call ErrorTimer.startPeriodic(500);
  }

  void signalFailure() {
    call ErrorTimer.startPeriodic(250);
  }
  
  TransmitBeginMsg* prepareTransmitBeginMsg() {
    TransmitBeginMsg* msg = (TransmitBeginMsg*)call SerialPacket.getPayload(&packet, sizeof(TransmitBeginMsg));
    if (msg == NULL) {
      signalFailure();
    }
    if (call SerialPacket.maxPayloadLength() < sizeof(TransmitBeginMsg)) {
      signalFailure();
    }
    return msg;
  }
  
  task void sendTransmitBeginMsg() {
    TransmitBeginMsg* msg = prepareTransmitBeginMsg();
    msg->bufferSize = 53; // TODO: Fix this by sending something meaningful
    
    if (call SerialSend.send[AM_TRANSMIT_BEGIN_MSG](AM_BROADCAST_ADDR, &packet, sizeof(TransmitBeginMsg)) == SUCCESS) {
      atomic {
        state = STATE_SENDING_START_REQUEST;
      }
    } else {
      post sendTransmitBeginMsg();
    }
  }
  
  task void startCommunicationTask() {
    atomic {
        currentRetry += 1;
    }
    post sendTransmitBeginMsg();
  }
  
  

  command void PCConnection.init(){
    call SerialControl.start();
  }
  
  /* REGION: Event handlers */

  event void SerialControl.startDone(error_t error){
    if (error == SUCCESS) {
      post startCommunicationTask();
    } else {
      signalFailure();
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
  
  event void ErrorTimer.fired(){
    call Leds.led0Toggle();
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
        }
      }
    } else {
      signalFailure();
    }
  }

  event message_t * SerialReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len){
    atomic {
      if (state == STATE_WAITING_START_RESPONSE) {
        
        if (msg_type == AM_TRANSMIT_BEGIN_ACK_MSG) {
          // We have received an ACK for the TransmitBegin message.
          // This means that we have established a connection to 
          // the PC.
          call Timeout.stop();
          
          state = STATE_ESTABLISHED;
          signal PCConnection.established();
        }
      }
    }
    return msg;
  }
}