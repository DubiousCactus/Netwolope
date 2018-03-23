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
  
  message_t Packet;
  uint8_t m_buffer[BUFFER_SIZE];
  
  /**
   * Read the first bytes of size (BUFFER_SIZE) of the Flash memory to 
   * determine previously written data.
   */
  task void initialReadTask();
  
 
  event void Boot.booted(){
  	call SerialControl.start();
  }

  event void BlockRead.readDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error){
    uint8_t* data;
    uint8_t i;
    ReceivePackageMsg * btrpkt;
    if (error == SUCCESS) {
        data = (uint8_t*)buf;
        btrpkt = (ReceivePackageMsg*)(call SerialPacket.getPayload(&Packet, sizeof (ReceivePackageMsg)));
        
        for(i = 0; i< 20; i++){
	        btrpkt->data[i]=data[i];    	
        }
        if(call UartSend.send[0](0, &Packet, 22) == SUCCESS){
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
		// TODO Auto-generated method stub
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