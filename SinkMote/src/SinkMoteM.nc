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
    interface Leds;
    interface PCConnection;
    interface Boot;
    interface Timer<TMilli> as ErrorTimer;
  }
}
implementation{
  enum {
    BUFFER_SIZE = 2048,
    PACKET_SIZE = 40
  };
  uint8_t buffer[BUFFER_SIZE];
  uint16_t head = 0;
  uint16_t tail = 0;
  
  task void sendNextPacket() {
    call PCConnection.send(&(buffer[head]), PACKET_SIZE);
    head += PACKET_SIZE;
  }

  event void Boot.booted(){
    uint16_t i;
    head = tail = 0;
    
    // Simulate a ring buffer
    for (i = 0; i < BUFFER_SIZE; i++) {
      buffer[i] = i; // TODO: Fix this
      tail = i;
    }
    
    call PCConnection.init();
  }
  
  event void PCConnection.established(){
    call Leds.led2On();
    post sendNextPacket();
  }

  event void PCConnection.error(PcCommunicationError error){
    call ErrorTimer.startPeriodic(250);
  }

  event void ErrorTimer.fired(){
    call Leds.led0Toggle();
  }

  event void PCConnection.sent(){
    call Leds.set(255);
  }
}