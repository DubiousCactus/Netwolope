module ProgramM{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as Timer;
    interface PCFileReceiver;
    interface OnlineCompressionAlgorithm as Compressor;
    interface RadioSender;
  }
}
implementation{
  enum {
    RADIO_DATA_CAPACITY = 50
  };
  
  uint8_t *dataToSend;
  uint16_t dataToSendLength;
  uint16_t sendIndex;
  
  task void sendNextPacketOverRadio() {
    uint8_t bufferSize;
    atomic {
      if (sendIndex == dataToSendLength){
        // All data are sent over the radio. 
        call Leds.led0On();
        return;
      }
      if (sendIndex + RADIO_DATA_CAPACITY > dataToSendLength) {
        bufferSize = (uint8_t)(dataToSendLength - sendIndex);
      } else {
        bufferSize = RADIO_DATA_CAPACITY;
      }
      call RadioSender.send(0, 0, &(dataToSend[sendIndex]), bufferSize);
      sendIndex += bufferSize;
    }
  }
  
  // EVENT HANDLERS
  
  event void Boot.booted(){
    dataToSendLength = 0;
    sendIndex = 0;
    call Compressor.init();
  }
  
  event void Compressor.initDone(){
    call RadioSender.start();
  }
  
  event void RadioSender.readyToSend(){
    call PCFileReceiver.init();
    call Leds.led1Toggle();
  }
  
  event void PCFileReceiver.initDone(){ 
     call Leds.led1On();
  }
  
  event void PCFileReceiver.fileBegin(uint32_t totalLength){
    call Compressor.fileBegin(totalLength);
  }
  
  event void PCFileReceiver.receivedData(uint8_t *data, uint16_t length){
    call Compressor.compress(data, length);
  }
  
  event void PCFileReceiver.fileEnd(){
    call Compressor.fileEnd();
  }
  
  event void Compressor.compressed(uint8_t *compressedData, uint16_t length){
    atomic {
      dataToSend = compressedData;
      dataToSendLength = length;
      sendIndex = 0;
    }
    
    post sendNextPacketOverRadio();
  }

  event void RadioSender.sendDone(){
    call Leds.led2Toggle();
    if (sendIndex < dataToSendLength) {
      post sendNextPacketOverRadio();
    } else {
      call PCFileReceiver.receiveMore();
    }
  }

  event void PCFileReceiver.error(PCFileSenderError error){
    call Leds.led0On();
  }
  
  event void Compressor.error(CompressionError error){
    call Leds.led0On();
  }

  event void Timer.fired(){ }
}