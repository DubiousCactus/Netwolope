module ProgramM{
  uses {
    interface Boot;
    interface Leds;
    interface PCFileReceiver;
    interface OnlineCompressionAlgorithm as Compressor;
    interface RadioSender;
    interface ErrorIndicator;
  }
}
implementation{
  enum {
    RADIO_DATA_CAPACITY = 50
  };
  
  uint8_t temp[RADIO_DATA_CAPACITY];
  uint8_t *dataToSend;
  uint16_t dataToSendLength;
  uint16_t sendIndex;
  uint16_t newSendIndex;
  
  task void sendNextPacketOverRadio() {
    uint8_t bufferSize;
    atomic {
      if (sendIndex == dataToSendLength){
        // All data are sent over the radio. 
        call ErrorIndicator.blinkRed(7);
        return;
      }
      if (sendIndex + RADIO_DATA_CAPACITY > dataToSendLength) {
        bufferSize = (uint8_t)(dataToSendLength - sendIndex);
      } else {
        bufferSize = RADIO_DATA_CAPACITY;
      }
      call Leds.led2Off();
      newSendIndex = sendIndex + bufferSize;
      call RadioSender.send(0, 0, &(dataToSend[sendIndex]), bufferSize);
    }
  }
  
  // EVENT HANDLERS
  
  event void Boot.booted(){
    dataToSendLength = 0;
    sendIndex = 0;
    call Compressor.init();
  }
  
  event void Compressor.initDone(){
    /*call RadioSender.start();*/
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
    
    /* Send over serial */

    /*post sendNextPacketOverRadio();*/
  }
  
  event void Compressor.compressDone(){
    /*call RadioSender.send(1, 0, temp, 0);*/
  }

  event void RadioSender.sendDone(){
    call Leds.led2On();
    atomic {
      sendIndex = newSendIndex;
      if (sendIndex < dataToSendLength) {
        post sendNextPacketOverRadio();
      } else {
        call PCFileReceiver.receiveMore();
      }      
    }
  }

  event void PCFileReceiver.error(PCFileReceiverError error){
    call ErrorIndicator.blinkRed(error);
  }
  
  event void Compressor.error(CompressionError error){
    call Leds.led0On();
  }
}
