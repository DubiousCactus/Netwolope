#include "FlashStorage.h"

module FlashStorageM{
  provides {
    interface FlashWriter;
    interface FlashReader;
    interface FlashError;
  }
  uses {
    interface BlockRead;
    interface BlockWrite;
    interface CircularBufferReader as ReadBuffer;
    interface CircularBufferWriter as WriteBuffer;
  }
}
implementation{
  enum {
    BUFFER_CAPACITY = 1024
  };
  
  uint8_t _buffer[BUFFER_CAPACITY];
  uint32_t _index;
  uint32_t _totalSize;
  
  task void writeTask() {
    static int posted;
    uint16_t writeSize, bytesAvailable;
    
    bytesAvailable = call ReadBuffer.available();
    if (bytesAvailable > BUFFER_CAPACITY) {
      writeSize = BUFFER_CAPACITY;
    } else {
      writeSize = bytesAvailable;
    }
    
    if (call ReadBuffer.readChunk(_buffer, writeSize) == SUCCESS) {
      posted = call BlockWrite.write(_index, _buffer, writeSize) == SUCCESS;
    } else {
      signal FlashError.onError(3);
    }
    
    if (!posted) post writeTask();
  }
  
  task void readTask() {
    static int posted;
    uint16_t readSize, bytesFree;
    
    bytesFree = call WriteBuffer.getFreeSpace();
    if (bytesFree > BUFFER_CAPACITY) {
      readSize = BUFFER_CAPACITY;
    } else {
      readSize = bytesFree;
    }
    
    if (_index + readSize > _totalSize) {
      readSize = _totalSize - _index;
    }
    
    posted = call BlockRead.read(_index, _buffer, readSize) == SUCCESS;
    if (!posted) post readTask();
  }
  
  command void FlashWriter.prepareWrite(uint32_t bytesToWrite){
    _index = 0;
    _totalSize = bytesToWrite;
    call BlockWrite.erase();
  }

  command void FlashReader.prepareRead(uint32_t bytesToRead){
    _index = 0;
    _totalSize = bytesToRead;
    call WriteBuffer.clear();
  }

  command void FlashWriter.writeNextChunk(){
    post writeTask();
  }
  
  command void FlashReader.readNextChunk(){
    if (_index < _totalSize) {
      post readTask();
      return;
    }
    signal FlashError.onError(4);
  }
  
  command bool FlashReader.isFinished(){
    return _index == _totalSize;
  }

  event void BlockRead.readDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error){
    if (error != SUCCESS) {
      signal FlashError.onError(3);
      return;
    }
    
    _index += len;
    call WriteBuffer.writeChunk(_buffer, len);
    if (call WriteBuffer.getFreeSpace() > 0 && _index < _totalSize) {
      post readTask();
    } else {
      signal FlashReader.chunkRead();
    }
  }
  
  event void BlockWrite.writeDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error){
    if (error != SUCCESS) {
      signal FlashError.onError(3);
      return;
    }
    
    _index += len;
    if (call ReadBuffer.available() > 0) {
      post writeTask();
    } else {
      call BlockWrite.sync();
    }
  }

  event void BlockWrite.syncDone(error_t error){
    if (error == SUCCESS) {
      signal FlashWriter.chunkWritten();
    } else {
      signal FlashError.onError(3);
    }
  }

  event void BlockWrite.eraseDone(error_t error){
    if (error == SUCCESS) {
      signal FlashWriter.readyToWrite();
    } else {
      signal FlashError.onError(3);
    }
  }
  
  event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error){
    // TODO Auto-generated method stub
  }
}