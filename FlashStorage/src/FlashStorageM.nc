module FlashStorageM {
  uses {
    interface Boot;
    interface Leds;
    interface FlashStorage;
  }
}
implementation {
  enum {
    BUFFER_SIZE = 10
  };
  uint8_t buffer[BUFFER_SIZE];
  
  event void Boot.booted(){
    uint8_t i;
    
    for (i = 0; i < BUFFER_SIZE; i++) {
      buffer[i] = i;
    }
    
    call Leds.led1On();
    call FlashStorage.init(FALSE);
  }

  event void FlashStorage.initialised(uint32_t size){
    if (size == 0) {
      call Leds.set(0);
      //call FlashStorage.write(buffer, BUFFER_SIZE);
    } else {
      call Leds.set(255);
    }
  }

  event void FlashStorage.writeDone(){
    call Leds.led2On();
  }

  event void FlashStorage.error(error_t error){
    call Leds.led0On();
  }
}