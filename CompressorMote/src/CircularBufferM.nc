generic module CircularBufferM(uint16_t CAPACITY) {
  provides {
    interface CircularBufferReader as Reader;
    interface CircularBufferWriter as Writer;
  }
}
implementation{
  uint8_t _buf[CAPACITY];
  uint16_t _start = 0;
  uint16_t _end = 0;
  
  inline uint16_t available() {
    if (_start <= _end)
      return _end - _start;
    else
      return CAPACITY - _start + _end;
  }
  
  inline uint16_t getFreeSpace() { 
    return CAPACITY - available() - 1; 
  }

  command uint16_t Reader.available(){
    return available();
  }
  
  command error_t Reader.read(uint8_t *byte){
    if (_start == _end) {
      // Nothing in the buffer
      return FAIL;
    } else {
      *byte = _buf[_start++];
      if (_start == CAPACITY) _start = 0;
      return SUCCESS;
    }
  }

  command error_t Reader.readChunk(uint8_t *buffer, uint16_t size){
    static uint16_t i;
    if (available() < size) {
      // Requested size is larger than what is available.
      return FAIL;
    }
    for (i = 0; i < size; i++) {
      buffer[i] = _buf[_start++];
      if (_start == CAPACITY) _start = 0;
    }
    return SUCCESS;
  }
  
  command void Writer.clear(){
    _start = 0;
    _end = 0;
  }

  command error_t Writer.write(uint8_t byte){
    if (_end + 1 == _start || (_start == 0 && _end + 1 == CAPACITY)) {
      return FAIL;
    }
    _buf[_end++] = byte;
    if (_end == CAPACITY) _end = 0;
    return SUCCESS;
  }

  command error_t Writer.writeChunk(uint8_t *buffer, uint16_t size){
    static uint16_t i;
    if (getFreeSpace() < size) {
      return FAIL;
    }
    for (i = 0; i < size; i++) {
      _buf[_end++] = buffer[i];
      if (_end == CAPACITY) _end = 0;
    }
    return SUCCESS;
  }

  command uint16_t Writer.getFreeSpace(){
    return getFreeSpace();
  }
}