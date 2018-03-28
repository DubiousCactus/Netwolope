/**
 * This component forwards data received on the radio to UART.  
 * 
 * <p>This component works as a one-way base station i.e., it forwards
 * data received by the CompressorMote to the PC. We assume that the PC 
 * sits on the serial link. On the radio link, we have the 
 * ComprossorMote.</p> 
 * 
 * <p>The LEDs are programmed as follows:</p>
 * <ul>
 *   <li><strong>Red LED</strong> is turned on if the buffer is 
 *   full</li>
 *   <li><strong>Green LED</strong> is turned on when the first bytes
 *   is received over the radio</li>
 * </ul>
 * 
 * @author Omar Ali Sheikh
 * @date 19 March 2018
 */
 

#include "AM.h"
#include "Serial.h"
#include "SinkMote.h"

module SinkMoteM @safe() {
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as ErrorTimer;
    interface Timer<TMilli> as SerialTimer;
    
    interface SplitControl as SerialControl;
    interface Packet as SerialPacket;
    interface AMPacket as SerialAMPacket;
    interface AMSend as SerialSend[am_id_t msg_type];
    
    interface SplitControl as RadioControl;
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;
    interface Receive as RadioReceive[am_id_t id];
  }
}
implementation{

  enum {
    QUEUE_SIZE = 12
  };
  
  // Allocate memory for the queue
  message_t  queueArray[QUEUE_SIZE];
  
  message_t serialPacket;
  
  // Allocate memory for pointers to each element of the queue.
  message_t  * ONE_NOK queuePointers[QUEUE_SIZE];
  uint8_t    queueHead, queueTail;
  bool       queueFull, serialBusy;

  
  task void serialSendTask();

  void signalPacketDropped();

  void signalFailure();
  PartialDataMsg* prepareSerialMsg();


  event void Boot.booted(){
    uint8_t i;
    
    // Set pointers of the queue
    for (i = 0; i < QUEUE_SIZE; i++)
      queuePointers[i] = &queueArray[i];
      
    // Initialize queue
    queueHead = queueTail = 0;
    queueFull = TRUE;
    
    serialBusy = FALSE;
    
    //call RadioControl.start();
    call SerialControl.start();
  }
  
  event void SerialControl.startDone(error_t error) {
    if (error == SUCCESS) {
      queueFull = FALSE;
      call SerialTimer.startPeriodic(5000);
    }
  }

  event void SerialTimer.fired(){
    uint8_t i;
    PartialDataMsg* pdm = prepareSerialMsg();
    call Leds.led1Toggle();
    
    for (i = 0; i < 20; i++) {
      pdm->data[i] += i+1;
    }
    
    if (call SerialSend.send[AM_PARTIAL_DATA_MSG](AM_BROADCAST_ADDR, &serialPacket, sizeof(PartialDataMsg)) == SUCCESS) {
      //Send success;
    }
  }

  event void RadioControl.startDone(error_t error){
    // TODO Auto-generated method stub
  }
  
  event void SerialControl.stopDone(error_t error) { }

  event void RadioControl.stopDone(error_t error) { }
  
  event message_t * RadioReceive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len){
    message_t *ret = msg;

    atomic {
      if (!queueFull) {
          ret = queuePointers[queueHead];
          queuePointers[queueHead] = msg;
        
          queueHead = (queueHead + 1) % QUEUE_SIZE;
        
          if (queueHead == queueTail) { 
          queueFull = TRUE;
          }
          
          if (!serialBusy) {
            post serialSendTask();
            serialBusy = TRUE;
          }
        } else {
          signalPacketDropped();
        }
    }
    
    return ret;
  }
  
  event void SerialSend.sendDone[am_id_t msg_type](message_t *msg, error_t error){
    if (error != SUCCESS) {
      signalFailure();
    } else {
      /*
      atomic {
        if (msg == queuePointers[queueTail]) {
            if (++queueTail >= QUEUE_SIZE)
              queueTail = 0;
            if (queueFull)
              queueFull = FALSE;
        }
      }
      post serialSendTask();
      */
    }
  }
  
  event void ErrorTimer.fired(){
    call Leds.led0Toggle();
  }
  
  void signalPacketDropped() {
    call ErrorTimer.startPeriodic(500);
  }

  void signalFailure() {
    call ErrorTimer.startPeriodic(250);
  }
  
  PartialDataMsg* prepareSerialMsg() {
    
    PartialDataMsg* pdm = (PartialDataMsg*)call SerialPacket.getPayload(&serialPacket, sizeof(PartialDataMsg));
    if (pdm == NULL) {
      signalFailure();
    }
    if (call SerialPacket.maxPayloadLength() < sizeof(PartialDataMsg)) {
      signalFailure();
    }
    
    return pdm;
  }
  
  task void serialSendTask() {
    uint8_t len;
    am_id_t id;
    am_addr_t addr, src;
    message_t* msg;
    
    atomic {
      if (queueHead == queueTail && !queueFull) {
        serialBusy = FALSE;
        return;
      }
    }
    
    msg = queuePointers[queueTail];
    
    len = call RadioPacket.payloadLength(msg);
    id = call RadioAMPacket.type(msg);
    addr = call RadioAMPacket.destination(msg);
    src = call RadioAMPacket.source(msg);
    call SerialPacket.clear(msg);
    call SerialAMPacket.setSource(msg, src);

    if (call SerialSend.send[AM_PARTIAL_DATA_MSG](addr, msg, len) == SUCCESS) {
      call Leds.led1Toggle();
    } else {
      signalFailure();
      post serialSendTask();
    }
  }
}