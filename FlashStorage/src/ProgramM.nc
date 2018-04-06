#include "PCConnection.h"
#include "FlashStorage.h"

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
    // 1) Erase flash storage
    call FlashStorage.init(TRUE);
  }

  event void FlashStorage.initialised(uint32_t size){
    // 2) Once the flash is erased, start a PC connection
    call PCConnection.init();
  }

  event void PCConnection.initDone(){   
    // 3) Ready to receive incoming data from the PC
  }
  
  event void PCConnection.fileBegin(uint32_t totalSize){
    // 4) PC wants to transfer a new file.
  }

  event void PCConnection.receivedData(uint8_t *data, uint16_t length){
    // 5) PC transfered part of the file to the PC
    // Store the received data to flash
    call FlashStorage.write(data, length);
  }

  event void FlashStorage.writeDone(){
    // 6) When data has been written to the flash
    // request PC to send more data
    call PCConnection.receiveMore();
  }
  
  event void PCConnection.fileEnd(){
    // 7) This event is automatically signalled 
    // when PC has finished transferring the file.
    // At this point, we can start the compression.
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

  event void FlashStorage.error(FlashStorageError error){
    if (error == FS_ERR_WRITE_FAILED) {
      call Timer.startPeriodic(500);
    } else if (error == FS_ERR_READ_FAILED) {
      call Timer.startPeriodic(1000);
    } else if (error == FS_ERR_INVALID_STATE) {
      call Timer.startPeriodic(2000);
    } else if (error == FS_ERR_UNKNOWN) {
      call Timer.startPeriodic(3000);
    }
  }

  event void Timer.fired(){
    call Leds.led0Toggle();
  }

  event void FlashStorage.readDone(){
    // TODO Auto-generated method stub
  }
}