#include <UserButton.h>
#include "printf.h"

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
  uint16_t _imageWidth;
  
  event void ButtonNotify.notify(button_state_t state){
    if ( state == BUTTON_PRESSED ) {
      call Leds.set(255);
    } else if (state == BUTTON_RELEASED) {
      call Leds.set(0);
      call FlashReader.prepareRead();
    }
  }
  
  event void Boot.booted(){
    printf("Booted\n");
    call ButtonNotify.enable();
    call PCFileReceiver.init();
  }
  
  event void PCFileReceiver.initDone(){ 
     call Leds.set(0);
     call Leds.led1On();
  }
  
  event void PCFileReceiver.fileBegin(uint16_t width){
    call FlashWriter.prepareWrite(width);
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
    call FlashReader.prepareRead();
  }
  
  event void FlashReader.readyToRead(uint16_t width){
    _imageWidth = width;
    call RadioSender.init();
  }
  
  event void RadioSender.initDone(){ 
    call RadioSender.sendFileBegin(_imageWidth, call Compressor.getCompressionType());
  }
  
  event void RadioSender.fileBeginAcknowledged(){ 
    call Compressor.fileBegin(_imageWidth);
    call FlashReader.readNextChunk();
    call Leds.led1Toggle();
  }
  

  event void FlashReader.chunkRead(){
    bool isFinished = call FlashReader.isFinished();
    printf("Flash finished %u\n\n", isFinished);
    call Compressor.compress(isFinished);
  }
  
  event void Compressor.compressed(){
    printf("Sending compressed data\n");
    call RadioSender.sendPartialData();
  }

  event void RadioSender.sendDone(){
    printf("Send done!\n");
    if (call RadioSender.canSend()) {
      call RadioSender.sendPartialData();
      
    } else if (call FlashReader.isFinished()) {
      call RadioSender.sendEOF();
      call Leds.led2On();
      
    } else {
      call FlashReader.readNextChunk();
      call Leds.led1Toggle();
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
