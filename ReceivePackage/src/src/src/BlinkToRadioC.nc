#include <Timer.h>
#include "AM.h"
#include "BlinkToRadio.h"
#include "Serial.h"

module BlinkToRadioC {
	uses interface Boot;
	uses interface Leds;

	uses interface SplitControl as SerialControl;
	uses interface Receive as UartReceive[am_id_t id];
}
implementation {

	bool uartBusy, uartFull;
	nx_uint8_t buffer[5000];
	nx_uint16_t index;

	event void Boot.booted() {
		index = 0;
		call Leds.led1On();
		call SerialControl.start();
	}

	event void SerialControl.stopDone(error_t error){}

	event void SerialControl.startDone(error_t error){
		if(error== SUCCESS){
			uartFull = FALSE;
		}
	}

	event message_t * UartReceive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len){
	  //ensure that the length of the message is what is expected
	  /*if (len == sizeof(BlinkToRadioMsg)) {
	  	//The message payload is cast to a structure pointer of type BlinkToRadioMsg* and assigned to a local variable
	    BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
	    	call Leds.set(btrpkt->counter);
	  }*/
	  
	  if (len == sizeof(ReceivePackageMsg)) {
	  	// The message payload is cast to a structure pointer of type ReceivePackageMsg* 
	  	// and assigned to a local variable
	    ReceivePackageMsg* btrpkt = (ReceivePackageMsg*)payload;
	    uint16_t i;
		
		for(i = 0; i< btrpkt->datalength; i++ ){
			buffer[index] = btrpkt->data[i];
			index++;
		}	    
	  }
	  call Leds.set(buffer[index%7]);
	  	  
		/*uint16_t i;
		nx_uint8_t* data = (nx_uint8_t*)payload;
		
		for(i = 0; i< len; i++ ){
			buffer[index] = data[i];
			index++;
		}
		
		call Leds.set(buffer[index%7]);*/ //to test if the data is correct 
		

		return msg;
		
	}
}