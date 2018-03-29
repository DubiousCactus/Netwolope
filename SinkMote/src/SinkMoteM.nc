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
  }
}
implementation{

  event void Boot.booted(){
    call PCConnection.init();
  }
  
  event void PCConnection.established(){
    call Leds.led2On();
  }
}