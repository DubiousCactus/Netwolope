module FlashTestM{
  uses {
    interface Boot;
    interface Leds;
    interface PCFileReceiver;
//    interface OnlineCompressionAlgorithm as Compressor;
    interface RadioSender;
    interface ErrorIndicator;
    interface FlashReader;
    interface FlashWriter;
    interface FlashError;
    interface CircularBufferReader as UncompressedBufferReader;
    interface CircularBufferWriter as UncompressedBufferWriter;
  }
}
implementation{
  bool radioBusy = FALSE;
  bool sendEof = FALSE;
  uint32_t fileSize;
  
  event void Boot.booted(){
    call PCFileReceiver.init();
  }
  
  event void PCFileReceiver.initDone(){ 
     call Leds.set(0);
     call Leds.led1On();
  }
  
  event void PCFileReceiver.fileBegin(uint32_t totalLength){
    fileSize = totalLength;
    call FlashWriter.prepareWrite(totalLength);
  }
    
  event void FlashWriter.readyToWrite(){
    call Leds.led1Toggle();
    call PCFileReceiver.sendFileBeginAck();
  }
  
  event void PCFileReceiver.receivedData(){
    call FlashWriter.writeNextChunk();
  }

  event void FlashWriter.chunkWritten(){
    call Leds.led1Toggle();
    call PCFileReceiver.receiveMore();
  }



  
  event void PCFileReceiver.fileEnd(){
    call RadioSender.init();
  }
  
  event void RadioSender.initDone(){ 
    call RadioSender.sendFileBegin(fileSize, 0);
  }
  
  event void RadioSender.fileBeginSent(){ 
    call FlashReader.prepareRead(fileSize);
    call FlashReader.readNextChunk();
  }

  event void FlashReader.chunkRead(){
    call RadioSender.sendPartialData();
  }
  
  event void RadioSender.sendDone(){
    if (call RadioSender.canSend()) {
      call RadioSender.sendPartialData();
      
    } else if (call FlashReader.isFinished()) {
      call RadioSender.sendEOF();
      call Leds.led2On();
      
    } else {
      call FlashReader.readNextChunk();
    }
  }
  
  
  event void PCFileReceiver.error(PCFileReceiverError error){
    call ErrorIndicator.blinkRed(error);
  }

  event void RadioSender.error(RadioSenderError error){
    call ErrorIndicator.blinkRed(error);
  }

  event void FlashError.onError(error_t error){
    call Leds.led0On();
  }
}