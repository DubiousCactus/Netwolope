
#include "AM.h"
#include "Serial.h"
#include "PCComm.h"

module PCCom{
  provides {
    interface PCConnection;
  }

  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as ErrorTimer;
    interface Timer<TMilli> as SerialTimer;
    
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
    msg->bufferSize = 50;
    
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
  
  /* REGION: Event handlers */

  event void Boot.booted(){
    call SerialControl.start();
  }

  event void SerialControl.startDone(error_t error){
    if (error == SUCCESS) {
      post startCommunicationTask();
    } else {
      call Leds.led0On();
    }
  }

  event void SerialControl.stopDone(error_t error){ }

  event void SerialTimer.fired(){
    
  }
  
  event void ErrorTimer.fired(){
    call Leds.led0Toggle();
  }

  event void SerialSend.sendDone[am_id_t msg_type](message_t *msg, error_t error){
    if (error == SUCCESS) {
      atomic {
        if (state == STATE_SENDING_START_REQUEST) {
          state = STATE_WAITING_START_RESPONSE;
        }
      }
    } else {
      signalFailure();
    }
  }

  event message_t * SerialReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len){
    atomic {
      if (state == STATE_WAITING_START_RESPONSE) {
        
      }
    }
    return msg;
  }
}