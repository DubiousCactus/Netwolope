#include <Timer.h>
#include "AM.h"
#include "DataReceiver.h"
#include "Serial.h"

#define BUFFER_SIZE 5000

module DataReceiverC{
	uses interface Boot;
	uses interface Leds;

	uses interface SplitControl as SerialControl;
	uses interface Receive as UartReceive[am_id_t id];
}
implementation{
	
	nx_uint8_t buffer[BUFFER_SIZE];
	nx_uint16_t index;

	event void Boot.booted(){
		index = 0;
		call SerialControl.start();
	}

	event void SerialControl.startDone(error_t error){
		call Leds.led1On();
	}

	event void SerialControl.stopDone(error_t error){
		// 
	}
	
	event message_t * UartReceive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len){ 
	  if (len == sizeof(FrameMsg)) {
	    FrameMsg* btrpkt = (FrameMsg*)payload;
	    uint16_t i;
		for(i = 0; i< btrpkt->dataLength; i++ ){
          buffer[index] = btrpkt->data[i];
          index++;
		}	    
	  }
	  
	  call Leds.set(buffer[index%7]);
      return msg;
	}

}