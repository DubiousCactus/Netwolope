#include <UserButton.h>

#define MEASURE_MODE

module ProgramM {
  uses {
    interface Boot;
    interface Leds;
    interface PCFileReceiver;
    interface OnlineCompressionAlgorithm as Compressor;
    interface RadioSender;
    interface ErrorIndicator;
    interface FlashReader;
    interface FlashWriter;
    interface FlashError;
    interface CircularBufferReader as UncompressedBufferReader;
    interface CircularBufferWriter as UncompressedBufferWriter;
    interface Notify<button_state_t> as ButtonNotify;
  }
}
implementation {
  uint32_t fileSize;
  
  event void ButtonNotify.notify(button_state_t state){
    if ( state == BUTTON_PRESSED ) {
      call Leds.set(255);
    } else if (state == BUTTON_RELEASED) {
      call Leds.set(0);
      fileSize = 65554;
      call RadioSender.init();
    }
  }
  
  event void Boot.booted(){
    #ifdef MEASURE_MODE
    call ButtonNotify.enable();
    #endif
    #ifndef MEASURE_MODE
    call PCFileReceiver.init();
    #endif
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
    call RadioSender.sendFileBegin(fileSize, call Compressor.getCompressionType());
  }
  event void RadioSender.fileBeginAcknowledged(){
    call Compressor.fileBegin(fileSize);
    call FlashReader.prepareRead(fileSize);
    call FlashReader.readNextChunk();
  }

  event void FlashReader.chunkRead(){
    call Compressor.compress(call FlashReader.isFinished());
  }
  
  event void Compressor.compressed(){
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
    call ErrorIndicator.blinkRed(2);
  }

  event void Compressor.error(CompressionError error){
    call ErrorIndicator.blinkRed(3);
  }
}