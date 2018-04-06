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
#include "PCFileSender.h"

module SinkMoteM @safe() {
  uses {
    interface Leds;
    interface PCFileSender;
    interface Boot;
    interface Timer<TMilli> as ErrorTimer;
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;
  }
}
implementation{
  enum {
    MSG_QUEUE_CAPACITY = 10,
    PAYLOAD_CAPACITY = 50
  };
  
  typedef nx_struct {
    message_t messages[MSG_QUEUE_CAPACITY];
    nx_uint8_t nextOut;
    nx_uint8_t nextIn;
    nx_uint8_t size;
  } MessageQueue;

  MessageQueue queue;
  bool isEOFBeingSent;
  
  task void sendNextPacket() {
    atomic {
      if (queue.size > 0) {
        message_t* msg = &(queue.messages[queue.nextOut]);
        call PCFileSender.sendMessage(msg, PAYLOAD_CAPACITY);
      }
    }
  }

  event void Boot.booted(){
    uint16_t i, j, counter;
    
    isEOFBeingSent = FALSE;
    
    queue.nextIn = 0;
    queue.nextOut = 0;
    queue.size = 0;
    
    // Simulate that we have received data from another mote
    for (i = 0; i < 5; i++) {
      message_t* msg = &(queue.messages[i]);
      uint8_t* data = (uint8_t*)call RadioPacket.getPayload(msg, PAYLOAD_CAPACITY);
      for (j = 0; j < PAYLOAD_CAPACITY; j++) {
        data[j] = (uint8_t)counter;
        counter++;
      }
      queue.size++;
      queue.nextIn = i+1;
    }
    
    call PCFileSender.init();
  }
  
  event void PCFileSender.established(){
    call Leds.led2On();
    post sendNextPacket();
  }

  event void PCFileSender.error(PCFileSenderError error){
    call ErrorTimer.startPeriodic(250);
  }

  event void ErrorTimer.fired(){
    call Leds.led0Toggle();
  }

  event void PCFileSender.sent(){
    call Leds.set(255);
    
    if (isEOFBeingSent == TRUE) {
      isEOFBeingSent = FALSE;
      return;
    }

    atomic {
      // Remove last message from the queue
      queue.nextOut += 1;
      queue.size -= 1;
      if (queue.nextOut >= MSG_QUEUE_CAPACITY) {
        queue.nextOut = 0;
      }
    }
    
    if (queue.size > 0) {
      post sendNextPacket();
    } else {
      isEOFBeingSent = TRUE;
      call PCFileSender.sendEOF();
    }
  }
}