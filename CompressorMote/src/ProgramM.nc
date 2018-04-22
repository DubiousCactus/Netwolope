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
  bool radioBusy = FALSE;
  bool sendEof = FALSE;
  
  event void Boot.booted(){
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
  
  event void RadioSender.fileBeginAcknowledged(){
    call PCFileReceiver.sendFileBeginAck();
  }
  
  event void PCFileReceiver.receivedData(){
    call Compressor.compress(FALSE);
  }
  
  event void Compressor.compressed(){
    radioBusy = TRUE;
    call RadioSender.sendPartialData();
  }

  event void RadioSender.sendDone(){
    radioBusy = FALSE;
    call PCFileReceiver.receiveMore();
    if (sendEof == TRUE) {
      call RadioSender.sendEOF();
      sendEof = FALSE;
    }
  }
  
  event void PCFileReceiver.fileEnd(){
    call Leds.led2On();
    call Compressor.compress(TRUE);
  }
  
//  event void Compressor.compressDone(){
//    if (radioBusy == TRUE) {
//      sendEof = TRUE;
//    } else {
//      call RadioSender.sendEOF();
//    }
//  }

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