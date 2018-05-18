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
    interface CircularBufferError as UncompressedBufferError;
    interface CircularBufferError as CompressedBufferError;
  }
}
implementation {
  uint16_t _imageWidth;
  uint16_t _sendDoneCounter = 0;
  
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
    call Compressor.compress(isFinished);
  }
  
  event void Compressor.compressed(){
    printf("Sending compressed data\n");
    printfflush();
    call RadioSender.sendPartialData();
  }

  event void RadioSender.sendDone(){
    if (call RadioSender.canSend()) {
      _sendDoneCounter += 1;
      call RadioSender.sendPartialData();
      
    } else if (call FlashReader.isFinished()) {
      printf("Sending EOF to SinkMote!\n");
      printfflush();
      call RadioSender.sendEOF();
      call Leds.led2On();
      
    } else {
      _sendDoneCounter = 0;
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

  event void UncompressedBufferError.error(uint8_t code){
    call ErrorIndicator.blinkRed(code);
  }

  event void CompressedBufferError.error(uint8_t code){
    call ErrorIndicator.blinkRed(code);
  }
}
