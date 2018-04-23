module RunLengthEncoderM{
  provides interface OnlineCompressionAlgorithm as Compressor;
  uses {
    interface CircularBufferReader as InBuffer;
    interface CircularBufferWriter as OutBuffer;
  }
}
implementation{

  command void Compressor.fileBegin(uint32_t totalLength){
    call OutBuffer.clear();
  }
  
  command void Compressor.compress(bool last){
    uint16_t avail, i;
    uint8_t currentVal, beginRunVal, count;
    
    avail = call InBuffer.available();
    
    if (avail > 0) {
      call InBuffer.read(&beginRunVal);
      count = 1;
      
      for (i = 1; i < avail; i++) {
        call InBuffer.read(&currentVal);
        
        if (beginRunVal == currentVal && count < 254) {
          count++;
        } else {
          call OutBuffer.write(beginRunVal);
          call OutBuffer.write(count);
          beginRunVal = currentVal;
          count = 1;
        }
      }
      call OutBuffer.write(beginRunVal);
      call OutBuffer.write(count);
    }
    
    signal Compressor.compressed();
  }

  command uint8_t Compressor.getCompressionType(){
    return 1;
  }
}