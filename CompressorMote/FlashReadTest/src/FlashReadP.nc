#include <Timer.h>
#include "AM.h"
#include "FlashRead.h"
#include "Serial.h"


module FlashReadP{
	uses {
    interface Boot;
    interface Leds;
    interface BlockRead;
    interface SplitControl as SerialControl;
    interface Packet as SerialPacket;
    interface AMPacket as SerialAMPacket;
    interface AMSend as UartSend[am_id_t id];
    interface Timer<TMilli> as Timer0;  		
	}
}
implementation{
  enum {
    BUFFER_SIZE = 100,
    INITIAL_BUFFER_SIZE = 8,
    STATUS_READ_DATA = 7,
    STATUS_READ_INVALID_LEN = 6,
    STATUS_READ_FAILED = 5,
    STATUS_DATA_SYNCED = 4
  };
  
  message_t packet;
  uint8_t m_buffer[BUFFER_SIZE];
  
  /**
   * Read the first bytes of size (BUFFER_SIZE) of the Flash memory to 
   * determine previously written data.
   */
  task void initialReadTask();
  task void uartSendTask();  
 
  event void Boot.booted(){
  	call SerialControl.start();
  }
  
  
task void uartSendTask() {
	
}  

  event void BlockRead.readDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error){
    uint8_t* data;
    uint8_t i, datalength, counter = 0;
    uint8_t startindex;
    ReceivePackageMsg * btrpkt;
    if (error == SUCCESS) {
        data = (uint8_t*)buf;
        btrpkt = (ReceivePackageMsg*)(call SerialPacket.getPayload(&packet, sizeof(ReceivePackageMsg)));

		/*
		 * Parameters that should be set. 
		 * startindex - the startindex in the buffer
		 * btrpkt->type - the type of the package. (not in use right now)
		 * btrpkt->datalength - the length of the package
		 */
		startindex = 0; //20 is the start of second package if we send a package of 20 data
        btrpkt->type = 03;
        datalength = sizeof(ReceivePackageMsg);
        btrpkt->datalength=datalength;
        
        /*
         * The following code determines what data
         * should be send to the serial port.
         */
        
        for(i = startindex; i< startindex+datalength; i++){
	        btrpkt->data[counter]=data[i];
	        counter++;    	
        }
        
        if(call UartSend.send[0](0, &packet, 22) == SUCCESS){
        	call Leds.led2On();
        }
        else{
        	call Leds.led0On();
        }
            	
    } else {
      // Reading was not successful.
      post initialReadTask();
    }
  }

  event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error){
    
  }

  task void initialReadTask() {
    static int posted;
    posted = call BlockRead.read(0,                 // position in the flash
                               &m_buffer,           // pointer to the buffer
                               BUFFER_SIZE  // amount of bytes to read
                               ) == SUCCESS;
    if (!posted) post initialReadTask();
  }
   
  /**
   * Using Timer to send the data from flash every 1sek.
   */
	event void SerialControl.startDone(error_t error){
		call Leds.led1On();
		call Timer0.startPeriodic( 1000 );		
	}

	event void SerialControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void UartSend.sendDone[am_id_t id](message_t *msg, error_t error){
		/*if (error != SUCCESS)
      		call Leds.led2On();
        **/
	}
  /**
   * Toggle led1 every 1sek.
   */
	event void Timer0.fired(){
		post initialReadTask();
		call Leds.led1Toggle();
		// TODO Auto-generated method stub
	}
}