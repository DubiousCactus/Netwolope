#include "FlashStorage.h"
#include "printf.h"

module FlashStorageM {
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
implementation {
  
  enum {
    BUFFER_CAPACITY = 1024,
    PREAMPLE_SIZE = 2,
  };
  
  uint8_t _buffer[BUFFER_CAPACITY];
  uint32_t _index;
  uint32_t _endIndex;
  uint16_t _imageWidth = 0;
  bool readingPreamble = FALSE;
  bool writingPreamble = FALSE;
  
  task void writePreample() {
    static int posted;
    uint16_t * preambleArr;
    
    // Convert byte array to 16-bit integer array
    // to write the image width
    preambleArr = (uint16_t *)_buffer;
    preambleArr[0] = _imageWidth;
    
    writingPreamble = TRUE;
    posted = call BlockWrite.write(0, _buffer, PREAMPLE_SIZE) == SUCCESS;
    if (!posted) post writePreample();
  }
  
  task void readPreamble() {
    static int posted;
    readingPreamble = TRUE;
    
    posted = call BlockRead.read(0, _buffer, PREAMPLE_SIZE) == SUCCESS;
    if (!posted) post readPreamble();
  }
  
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
    uint16_t readSize;
    uint16_t bytesFree;

    bytesFree = call WriteBuffer.getFreeSpace();
    
    if (bytesFree > BUFFER_CAPACITY) {
      readSize = BUFFER_CAPACITY;
    } else {
      readSize = bytesFree;
    }
    
    if (_index + readSize > _endIndex) {
      readSize = _endIndex - _index;
    }
    
    posted = call BlockRead.read(_index, _buffer, readSize) == SUCCESS;
    if (!posted) post readTask();
  }
  
  command void FlashWriter.prepareWrite(uint16_t width){
    uint32_t width32 = width;
    _imageWidth = width;
    _index = PREAMPLE_SIZE;
    _endIndex = (width32 * width32) + PREAMPLE_SIZE;
    call BlockWrite.erase();
  }

  command void FlashReader.prepareRead(){
    _index = 0;
    _imageWidth = 0; // image width is set when preamble is read
    _endIndex = 0;  // computed when preamble is read
    call WriteBuffer.clear();
    post readPreamble();
  }

  command void FlashWriter.writeNextChunk(){
    post writeTask();
  }
  
  command void FlashReader.readNextChunk(){
    if (_index < _endIndex) {
      post readTask();
      return;
    }
    signal FlashError.onError(4);
  }
  
  command bool FlashReader.isFinished(){
    return _index == _endIndex;
  }

  event void BlockRead.readDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error){
    uint16_t * preambleArr;
    uint32_t imageWidth32;
    
    if (error != SUCCESS) {
      signal FlashError.onError(3);
      return;
    }
    
    if (readingPreamble == TRUE) {
      readingPreamble = FALSE;
      
      preambleArr = (uint16_t *)buf; 
      _imageWidth = preambleArr[0];
      imageWidth32 = _imageWidth;
      
      _index = PREAMPLE_SIZE;
      _endIndex = (imageWidth32 * imageWidth32) + PREAMPLE_SIZE;
      signal FlashReader.readyToRead(_imageWidth);
      return;
    }
    
    _index += len;
    
    call WriteBuffer.writeChunk(_buffer, len);
    if (call WriteBuffer.getFreeSpace() > 0 && _index < _endIndex) {
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
    
    if (writingPreamble == TRUE) {
      writingPreamble = FALSE;
      signal FlashWriter.readyToWrite();
      return;
    }
    
    _index += len;
    if (call ReadBuffer.available() > 0) {
      post writeTask();
    } else {
      call BlockWrite.sync();
    }
  }

  event void BlockWrite.syncDone(error_t error) {
    if (error == SUCCESS) {
      signal FlashWriter.chunkWritten();
    } else {
      signal FlashError.onError(3);
    }
  }

  event void BlockWrite.eraseDone(error_t error) {
    if (error == SUCCESS) {
      post writePreample();
    } else {
      signal FlashError.onError(3);
    }
  }
  
  event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error){
    // TODO Auto-generated method stub
  }
}
