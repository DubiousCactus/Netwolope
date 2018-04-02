#include "PCConnection.h"

module ProgramM{
  uses {
    interface Boot;
    interface Leds;
    interface PCConnection;
    interface Timer<TMilli> as Timer;
  }
}
implementation{

  event void Boot.booted(){
    call PCConnection.init();
  }

  event void PCConnection.initDone(){
    
  }
  
  event void PCConnection.transmissionBegin(uint32_t totalSize){
    
  }

  event void PCConnection.receivedData(uint8_t *data, uint16_t length){
    call Leds.led1Toggle();
    call PCConnection.receiveMore();
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
}