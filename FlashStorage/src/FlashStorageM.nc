module FlashStorageM {
  uses {
    interface Boot;
    interface Leds;
    interface BlockRead;
    interface BlockWrite;
  }
}
implementation {
   
  enum {
    BUFFER_SIZE = 100,
    INITIAL_BUFFER_SIZE = 8,
    STATUS_READ_DATA = 7,
    STATUS_READ_INVALID_LEN = 6,
    STATUS_READ_FAILED = 5,
    STATUS_DATA_SYNCED = 4
  };
  
  uint8_t m_buffer[BUFFER_SIZE];
  
  /**
   * Read the first 8 bytes of the Flash memory to 
   * determine previously written data.
   */
  task void initialReadTask();
  
  /**
   * Write 8 bytes (0xD 0xE 0xA 0xD 0xB 0xE 0xE 0xF) to the Flash.
   * This task initiates the writing operation by called BlockWrite.erase().
   */
  task void beginWriteTask();
  
  /**
   * Completes the writing operation by calling BlockWrite.write()
   */
  task void endWriteTask();
   

  event void Boot.booted(){
    post initialReadTask();
    //call Leds.set(STATUS_READ_INVALID_LEN);
  }

  event void BlockRead.readDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error){
    uint8_t* data;
    if (error == SUCCESS) {
      
      if (len == 8) {
        data = (uint8_t*)buf;
        // Check that the returned data is correct
        if (data[0] == 0xD && data[1] == 0xE && data[2] == 0xA && 
            data[3] == 0xD && data[4] == 0xB && data[5] == 0xE && 
            data[6] == 0xE && data[7] == 0xF) {
            
            // Correctly retrieved data stored in Flash
            call Leds.set(STATUS_READ_DATA);
        } else {
          // Incorrect data read from the Flash.
          // We assume that this is the first time.
          post beginWriteTask();
        }
      } else {
        // Something went wrong. Returned data size is not 8 bytes.
        call Leds.set(STATUS_READ_INVALID_LEN);
      }
    } else {
      // Reading was not successful.
      call Leds.set(STATUS_READ_FAILED);
      post initialReadTask();
    }
  }

  event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error){
    
  }

  event void BlockWrite.writeDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error){
    if (error == SUCCESS) {
      // Sync MUST be called to ensure written data survives a reboot or crash.
      call BlockWrite.sync();
    }
  }

  event void BlockWrite.eraseDone(error_t error){
    if (error == SUCCESS) {
      post endWriteTask();
    }
  }

  event void BlockWrite.syncDone(error_t error){
    if (error == SUCCESS) {
      call Leds.set(STATUS_DATA_SYNCED);
    }
  }
  
  task void initialReadTask() {
    static int posted;
    posted = call BlockRead.read(0,                 // position in the flash
                               &m_buffer,           // pointer to the buffer
                               INITIAL_BUFFER_SIZE  // amount of bytes to read
                               ) == SUCCESS;
    if (!posted) post initialReadTask();
  }
  
  task void beginWriteTask() {
    // Before data can written to Flash, we must erase it
    // Corresponding endWriteTask() is called by eraseDone() event
    call BlockWrite.erase();
  }
  
  task void endWriteTask() {
    m_buffer[0] = 0xD;
    m_buffer[1] = 0xE;
    m_buffer[2] = 0xA;
    m_buffer[3] = 0xD;
    m_buffer[4] = 0xB;
    m_buffer[5] = 0xE;
    m_buffer[6] = 0xE;
    m_buffer[7] = 0xF;
    
    call BlockWrite.write(0, &m_buffer, INITIAL_BUFFER_SIZE);
  }
  
}