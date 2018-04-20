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
  event void Boot.booted(){
    call Compressor.init();
  }
  
  event void Compressor.initDone(){
    call RadioSender.init();
  }
  
  event void RadioSender.initDone(){
    call PCFileReceiver.init();
  }
  
  event void PCFileReceiver.initDone(){ 
     call Leds.led1On();
  }
  
  event void PCFileReceiver.fileBegin(uint32_t totalLength){
    call Compressor.fileBegin(totalLength);
    call RadioSender.sendFileBegin(totalLength, call Compressor.getCompressionType());
  }
  
  event void RadioSender.fileBeginSent(){
    call PCFileReceiver.sendFileBeginAck();
  }
  
  event void PCFileReceiver.receivedData(uint8_t *data, uint16_t length){
    call Compressor.compress(data, length);
  }
  
  event void PCFileReceiver.fileEnd(){
    call Leds.led2On();
    call Compressor.fileEnd();
  }
  
  event void Compressor.compressed(uint8_t *compressedData, uint16_t length){
    call RadioSender.sendPartialData(compressedData, length);
  }
  
  event void Compressor.compressDone(){
    call RadioSender.sendEOF();
  }

  event void RadioSender.sendDone(){
    call PCFileReceiver.receiveMore();
  }

  event void PCFileReceiver.error(PCFileReceiverError error){
    call ErrorIndicator.blinkRed(error);
  }
  
  event void Compressor.error(CompressionError error){
    call Leds.led0On();
  }

  event void RadioSender.error(RadioSenderError error){
    call ErrorIndicator.blinkRed(error);
  }

}