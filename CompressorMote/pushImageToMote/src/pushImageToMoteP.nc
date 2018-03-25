#include <Timer.h>
#include "AM.h"
#include "ReceivePackage.h"
#include "Serial.h"


module pushImageToMoteP{
	uses interface Boot;
	uses interface Leds;
    uses interface BlockWrite;

	uses interface SplitControl as SerialControl;
	uses interface Receive as UartReceive[am_id_t id];	
}
implementation{
    enum {
    	BUFFER_SIZE = 5000
    };
	bool uartBusy, uartFull, flashReady;
	nx_uint8_t buffer[5000];
	nx_uint16_t head, tail, updatedTail; 
	uint16_t packagecount = 0;
   	task void beginWriteTask();
  
    task void initializeFlashTask();
   
	  
	event void Boot.booted() {
		head = 0;
		tail = 0;
		/* Erase flash */
		post initializeFlashTask();
 		/* Read data to flash */
		call SerialControl.start();
	}

	event void SerialControl.stopDone(error_t error){}

	event void SerialControl.startDone(error_t error){
		if(error== SUCCESS){
			uartFull = FALSE;
		}
	}

	event message_t * UartReceive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len){	  
	ReceivePackageMsg* btrpkt = (ReceivePackageMsg*)payload;  
	  if (len == sizeof(ReceivePackageMsg)) {
	  	// The message payload is cast to a structure pointer of type ReceivePackageMsg* 
	  	// and assigned to a local variable
	    
	    uint16_t i;
		/* To save type, datalength, data to the buffer. */
		buffer[head] = btrpkt->type;
		head++;
		buffer[head] = btrpkt->datalength;
		head++;
		for(i = 0; i< btrpkt->datalength; i++ ){
			buffer[head] = btrpkt->data[i];
			head++;
		}
		 
		packagecount++;   			

	  }else{
	  }
	  /* When last package is send */
	  if(btrpkt->type == 01){
	  	call Leds.led1On();	
	  	post beginWriteTask();	
	  }
		return msg;	
	}

  event void BlockWrite.writeDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error){
    if (error == SUCCESS) {
      // Sync MUST be called to ensure written data survives a reboot or crash.
      call BlockWrite.sync();
      
    }
  }

  event void BlockWrite.eraseDone(error_t error){
    if (error == SUCCESS) {
    	flashReady = TRUE;
    	call Leds.led0On();
    }else {
    	post initializeFlashTask();
    }
  }

  event void BlockWrite.syncDone(error_t error){
    if (error == SUCCESS) {
      tail = updatedTail;
  	  if(tail==head){
  		call Leds.led2On();
  	  }      
    }
  }
 
  task void initializeFlashTask() {
    // Before data can written to Flash, we must erase it
    // Corresponding endWriteTask() is called by eraseDone() event
    call BlockWrite.erase();
    flashReady = FALSE;  	
  }
  task void beginWriteTask() {
  	if(tail != head && flashReady == TRUE){
  		updatedTail = tail+(head-tail);
  		call BlockWrite.write(tail,&buffer, head-tail);
 
  	}
  }

}