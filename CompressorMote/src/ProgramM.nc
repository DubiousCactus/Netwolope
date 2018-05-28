#include <UserButton.h>

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
  
  event void ButtonNotify.notify(button_state_t state) {
    if (state == BUTTON_RELEASED) {
      call FlashReader.prepareRead();
    }
  }
  
  event void Boot.booted() {
    call ButtonNotify.enable();
    call PCFileReceiver.init();
  }
  
  event void PCFileReceiver.initDone() { 
     //call Leds.led1On();
  }
  
  event void PCFileReceiver.fileBegin(uint16_t width) {
    call FlashWriter.prepareWrite(width);
  }
    
  event void FlashWriter.readyToWrite() {
    call PCFileReceiver.sendFileBeginAck();
  }
  
  event void PCFileReceiver.receivedData() {
    call FlashWriter.writeNextChunk();
  }

  event void FlashWriter.chunkWritten() {
    call PCFileReceiver.receiveMore();
  }
  
  event void PCFileReceiver.fileEnd() {
    call FlashReader.prepareRead();
  }
  
  event void FlashReader.readyToRead(uint16_t width) {
    _imageWidth = width;
    call RadioSender.init();
  }
  
  event void RadioSender.initDone() { 
    call RadioSender.sendFileBegin(_imageWidth, call Compressor.getCompressionType());
  }
  
  event void RadioSender.fileBeginAcknowledged() { 
    call Compressor.fileBegin(_imageWidth);
    call FlashReader.readNextChunk();
  }
  
  event void FlashReader.chunkRead() {
    bool isFinished = call FlashReader.isFinished();
    call Compressor.compress(isFinished);
  }
  
  event void Compressor.compressed() {
    call RadioSender.sendPartialData();
  }

  event void RadioSender.sendDone() {
    if (call RadioSender.canSend()) {
      call RadioSender.sendPartialData();
      
    } else if (call FlashReader.isFinished()) {
      call RadioSender.sendEOF();
      
    } else {
      call FlashReader.readNextChunk();
    }
  }  
  
  event void PCFileReceiver.error(PCFileReceiverError error) {
    call ErrorIndicator.blinkRed(error);
  }

  event void RadioSender.error(RadioSenderError error) {
    call ErrorIndicator.blinkRed(error);
  }

  event void FlashError.onError(error_t error) {
    call ErrorIndicator.blinkRed(2);
  }

  event void Compressor.error(CompressionError error) {
    call ErrorIndicator.blinkRed(3);
  }

  event void UncompressedBufferError.error(uint8_t code) {
    call ErrorIndicator.blinkRed(code);
  }

  event void CompressedBufferError.error(uint8_t code) {
    call ErrorIndicator.blinkRed(code);
  }
}

