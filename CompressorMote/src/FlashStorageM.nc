#include "FlashStorage.h"

module FlashStorageM {
  provides {
    interface FlashStorage;
  }
  uses {
    interface Leds;
    interface BlockRead;
    interface BlockWrite;
  }
}
implementation {
  
  enum {
    BUFFER_CAPACITY = 100,
    PREAMBLE_SIZE = 8
  };
  
  typedef enum {
    STATE_UNKNOWN,
    STATE_READING_PREAMBLE,
    STATE_READING_DATA,
    STATE_WRITING_INITIAL_PREAMBLE,
    STATE_WRITING_DATA,
    STATE_WRITING_SIZE,
    STATE_READY
  } FlashStorageState;
  
  uint8_t buffer[BUFFER_CAPACITY];
  FlashStorageState state = STATE_UNKNOWN;
  uint32_t size = 0;
  
  task void wipeFlashTask() {
    if (call BlockWrite.erase() != SUCCESS) {
      signal FlashStorage.error(FS_ERR_ERASE_FAILED);
      //post wipeFlashTask();
    }
  }
  
  void verifyPreampleTask(void *buf, storage_len_t len) {
    uint8_t* byteArray;
    uint32_t* dataArray;
    
    byteArray = (uint8_t*)buf;
      
    // First 4 bytes, should be 0xDEAD 
    if (len == PREAMBLE_SIZE && byteArray[0] == 0xD && byteArray[1] == 0xE && byteArray[2] == 0xA && byteArray[3] == 0xD) {
      dataArray = (uint32_t*)buf;
      atomic {
        // Read the next 4 bytes as 32 bit unsigned integer
        size = dataArray[1];
        state = STATE_READY;
      }
      
      // Initialisation is done
      signal FlashStorage.initialised(size);
    } else {
      // Preamble is not as expected, wipe the flash
      post wipeFlashTask();
    }
  }
  
  task void writePreambleTask() {
    uint32_t* dataArray;
    atomic {
      buffer[0] = 0xD;
      buffer[1] = 0xE;
      buffer[2] = 0xA;
      buffer[3] = 0xD;
      buffer[4] = 0x0;
      buffer[5] = 0x0;
      buffer[6] = 0x0;
      buffer[7] = 0x0;
      
      // Convert byte array to int32 array
      dataArray = (uint32_t*)&(buffer);
      dataArray[1] = size;
      
      if (call BlockWrite.write(0, &buffer, PREAMBLE_SIZE) != SUCCESS) {
        signal FlashStorage.error(FS_ERR_WRITE_FAILED);
      }
    }
  }

  task void readPreampleTask() {
    static error_t result;
    atomic {
      result = call BlockRead.read(0,               // position in the flash
                               &buffer,             // pointer to the buffer
                               PREAMBLE_SIZE        // amount of bytes to read
                               );
      if (result == SUCCESS) {
	    state = STATE_READING_PREAMBLE;
      } else {
        post readPreampleTask();
      }
    }
  }

  command void FlashStorage.init(bool erase) {
    if (erase == TRUE) {
      post wipeFlashTask();
    } else {
      post readPreampleTask();
    }
  }
  
  command void FlashStorage.read(uint32_t fromIndex, uint8_t *data, uint16_t length) {
    atomic {
      if (call BlockRead.read(fromIndex, data, length) == SUCCESS) {
        state = STATE_READING_DATA;
      } else {
        signal FlashStorage.error(FS_ERR_WRITE_FAILED);
      }      
    }
  }
  
  command void FlashStorage.write(uint8_t *data, uint16_t length) {
    atomic {
      if (call BlockWrite.write(PREAMBLE_SIZE + size, data, length) == SUCCESS) {
        state = STATE_WRITING_DATA;
      } else {
        signal FlashStorage.error(FS_ERR_WRITE_FAILED);
      }      
    }
  }

  event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) {
    
  }

  event void BlockRead.readDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error) {
    if (error == SUCCESS) {
      atomic {
        if (state == STATE_READING_PREAMBLE) {
          verifyPreampleTask(buf, len);
          
        } else if (state == STATE_READING_DATA) {
          state = STATE_READY;
          signal FlashStorage.readDone();
        }
      }
    } else {
      // TODO: Signal an error
    }
  }

  event void BlockWrite.eraseDone(error_t error) {
    if (error == SUCCESS) {
      atomic {
        size = 0;
        state = STATE_WRITING_INITIAL_PREAMBLE;
      }
      post writePreambleTask();
    }
  }

  event void BlockWrite.syncDone(error_t error) {
    if (error == SUCCESS) {
      atomic {
        if (state == STATE_WRITING_INITIAL_PREAMBLE) {
          state = STATE_READY;
          signal FlashStorage.initialised(size);
          
        } else if (state == STATE_WRITING_DATA) {
          state = STATE_READY;
          signal FlashStorage.writeDone();          
        }
      }
    } else {
      // TODO: Handle error
    }
  }

  event void BlockWrite.writeDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error) {
    if (error == SUCCESS) {
      atomic {
        if (state == STATE_WRITING_DATA) {
          size += len;
        }
      }
      
      // Always call sync() after a write operation
      call BlockWrite.sync();
    } else {
      // TODO: Handle error
    }
  }
}
