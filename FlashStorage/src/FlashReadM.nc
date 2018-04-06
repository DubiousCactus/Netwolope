#include "ReceivePackage.h"

module FlashReadM{
	provides {
		interface FlashRead;
	}
	uses {
		interface Leds;
		interface BlockRead;
		interface AMSend as UartSend[am_id_t id];
		interface Packet as SerialPacket;
	}
}
implementation{
	enum {
		BUFFER_CAPACITY = 100
	};
	
	uint8_t m_buffer[BUFFER_CAPACITY];
	message_t packet;
	
	task void initialReadTask() {
	    static int posted;
	    posted = call BlockRead.read(0,                 // position in the flash
	                               &m_buffer,           // pointer to the buffer
	                               BUFFER_CAPACITY  // amount of bytes to read
	                               ) == SUCCESS;
	    if (!posted) post initialReadTask();		
	}

	event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error){
		// TODO Auto-generated method stub
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

	event void UartSend.sendDone[am_id_t id](message_t *msg, error_t error){
		// TODO Auto-generated method stub
	}
}