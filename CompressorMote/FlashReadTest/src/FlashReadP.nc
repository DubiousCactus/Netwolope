#include <Timer.h>
#include "AM.h"
#include "FlashRead.h"
#include "Serial.h"

/*
 * program that reads from the flash and send the data through the serial.
 * In this program it will send package until type = 01 and start over. 
 * make telosb install
 * export MOTECOM=serial@/dev/ttyUSB0:telosb 
 * java net.tinyos.tools.Listen
 * 
 */

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
    BUFFER_SIZE = 5000,
    INITIAL_BUFFER_SIZE = 8,
    STATUS_READ_DATA = 7,
    STATUS_READ_INVALID_LEN = 6,
    STATUS_READ_FAILED = 5,
    STATUS_DATA_SYNCED = 4
  };
  
  message_t packet;
  uint16_t count;
  uint8_t* data;
  bool locked = FALSE;
  uint8_t m_buffer[BUFFER_SIZE];
  
  /**
   * Read the first bytes of size (BUFFER_SIZE) of the Flash memory to 
   * determine previously written data.
   */
  task void initialReadTask(); 
  
  event void Boot.booted(){
  	post initialReadTask();
  	
  }


  event void BlockRead.readDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error){
    if (error == SUCCESS) {
    	 data = (uint8_t*)buf;
    	 call SerialControl.start();
           	
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
	event void UartSend.sendDone[am_id_t id](message_t *msg, error_t error){
	    if (&packet == msg) {
	      locked = FALSE;
	    }		
	}   
  /**
   * Using Timer to send the data from flash every 1sek.
   */
	event void SerialControl.startDone(error_t error){
	    if (error == SUCCESS) {
	      call Timer0.startPeriodic(1000);
	    }		
		//call Leds.led1On();
		//call Timer0.startPeriodic( 1000 );		
	}

	event void SerialControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}


  /**
   * Toggle led1 every 1sek.
   */
	event void Timer0.fired(){
		uint16_t i, datalength, counter = 0;
		uint16_t startindex;	
		if (locked) {
			return;
		}
		else {
	      ReceivePackageMsg* btrpkt = (ReceivePackageMsg*)call SerialPacket.getPayload(&packet, sizeof(ReceivePackageMsg));
	      if (btrpkt == NULL) {return;}
	      if (call SerialPacket.maxPayloadLength() < sizeof(ReceivePackageMsg)) {
		return;
	      }

	     /*
		 * Parameters that should be set. 
		 * startindex - the startindex in the buffer
		 * btrpkt->type - the type of the package. (not in use right now)
		 * btrpkt->datalength - the length of the package
		 */
		datalength = sizeof(ReceivePackageMsg);
		startindex = datalength*count;	
		count++;
       
        /*
         * The following code determines what data
         * should be send to the serial port.
         */
        btrpkt->type = data[startindex];
        startindex++;
		//to start over when type == 01      
	    if(btrpkt->type == 1){
	    	count = 0;
	    }        
        btrpkt->datalength = data[startindex];
        startindex++;
        for(i = startindex; i< startindex+datalength; i++){
	        btrpkt->data[counter]=data[i];
	        counter++;    	
        }
                
	      if (call UartSend.send[0](AM_BROADCAST_ADDR, &packet, sizeof(ReceivePackageMsg)) == SUCCESS) {
		locked = TRUE;
	      }	      
	    }
		
		call Leds.led1Toggle();
		// TODO Auto-generated method stub
	}
}