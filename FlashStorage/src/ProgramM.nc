#include "PCConnection.h"

module ProgramM{
  uses {
    interface Boot;
    interface Leds;
    interface PCConnection;
    interface FlashStorage;
    interface Timer<TMilli> as Timer;
  }
}
implementation{

  event void Boot.booted(){
  	/*
  	 * To erase flash when the mote is turned on
  	 */
  	call FlashStorage.init(TRUE);
    call PCConnection.init();
  }

  event void PCConnection.initDone(){
    
  }
  
  event void PCConnection.fileBegin(uint32_t totalSize){
    
  }

  event void PCConnection.receivedData(uint8_t *data, uint16_t length){
    call Leds.led1Toggle();
    call PCConnection.receiveMore();
    //if(flashReady == TRUE){
    //  call FlashStorage.write(data, length);
    //}
  }
  
  event void PCConnection.fileEnd(){
    call Leds.led2On(); 
  }

  event void PCConnection.error(PCConnectionError error){
    if (error == PCC_ERR_PACKET_DROPPED) {
      call Timer.startPeriodic(200);
    } else if (error == PCC_ERR_PROGRAMMER) {
      call Timer.startPeriodic(1000);
    } else if (error == PCC_ERR_SEND_FAILED) {
      call Timer.startPeriodic(2000);
    } else if (error == PCC_ERR_SERIAL_INIT_FAILED) {
      call Timer.startPeriodic(3000);
    }
  }

  event void Timer.fired(){
    call Leds.led0Toggle();
  }

	event void FlashStorage.writeDone(){
		//flashReady = TRUE;
		// TODO Auto-generated method stub
	}

	event void FlashStorage.initialised(uint32_t size){
		// Erase is done
		call Leds.led0On();
	}

	event void FlashStorage.error(error_t error){
		// TODO Auto-generated method stub
	}

	event void FlashStorage.readDone(){
		// TODO Auto-generated method stub
	}
}