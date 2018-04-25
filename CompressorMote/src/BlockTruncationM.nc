#include "OnlineCompressionAlgorithm.h"
#include "printf.h"

module BlockTruncationM{
  provides interface OnlineCompressionAlgorithm as Compressor;
  uses interface CircularBufferWriter as OutBuffer;
  uses interface CircularBufferBlockReader as BlockReader;
}
implementation{
  enum {
    BLOCK_SIZE = 4,
  };
  uint16_t _imageWidth;
  uint8_t compressbuffer[64];     // (encoder) converted to single bit (only 1 and 0)
  uint8_t binarybuffer[8];        // convert bytes to bits (e.g. 255 -> 11111111)
  uint8_t decompressbuffer[64];   // (decoder) converted to single bit (only 1 and 0)
  uint8_t decodebuffer[64]; // reconstructed block corresponding to a and b
  
  /* Calculate A^B */
  float Powerfunction(float A, uint16_t B){
    float ans = A;
    uint16_t i = 1;
    while(i < B){
      ans = ans * A;
      i++;
    }
    return ans;
  }
  int ABS(int N) { return ((N<0)?(-N):(N)); }
  
  float SquareRoot(float num) {
    float x1 = (num * (float)1) / (float)2;
    float x2= (x1 + (num / x1)) / (float)2;
    while(ABS((uint8_t)(x1 - x2)) >= 0.0000001) {
    x1 = x2;
    x2 = (x1 + (num / x1)) / 2;
    }
    return x2;
  }

  float Root(float n){
    float lo = 0, hi = n, mid;
    int i;
    for(i = 0 ; i < 1000 ; i++){
      mid = (float)((lo+hi)/2);
      if(mid*mid == n) return mid;
      if(mid*mid > n){
        hi = mid;
      }else{
        lo = mid;
      }
    }
    return mid;
  }
  short isqrt(short num) {
     short res = 0;
     short bit = 1 << 14; // The second-to-top bit is set: 1 << 30 for 32 bits
  
     // "bit" starts at the highest power of four <= the argument.
     while (bit > num)
       bit >>= 2;
       
     while (bit != 0) {
       if (num >= res + bit) {
         num -= res + bit;
         res = (res >> 1) + bit;
       }
       else
         res >>= 1;
       bit >>= 2;
     }
     return res;
  }     
  
  /*Calculate mean of the data array */
  float Mean(uint8_t *data, uint16_t length){
    uint8_t i;
    float sum = 0,mean = 0;
    for(i = 0; i < length; ++i){
      sum += data[i];
    }

    mean = (sum/(float)length);
    return mean;
  }
  
  /*Calculate standard deviation of the data array */
  float StandardDeviation(uint8_t *data, uint16_t length){
    float standardDeviation = 0;
    uint8_t i;
    float mean;
    mean = Mean(data, length);

    for(i=0; i<length; ++i){
      standardDeviation += Powerfunction(data[i] - mean, 2);
    }
    return SquareRoot((float)standardDeviation/(float)length);
  }
  
  float std_var_stable (uint8_t *a, uint16_t n) {
     uint8_t i =0;
     float mean = 0;
     float M2 = 0;
     float delta;
     if (n == 0) return 0;
     for(i = 0; i < n; ++i) {
      delta = a[i] - mean;
      mean += delta / (float)(i + 1);
      M2 += delta * (float)(a[i] - mean);
     }
     return M2/(float)n;
  }   
  
  void EncoderConvertToSingleBit(uint8_t *data,uint16_t length,float meanvalue){
    uint8_t i;
    for(i = 0; i<length; i++){
      if(data[i] > meanvalue){
        compressbuffer[i] = 1;
      }
      else{
        compressbuffer[i] = 0;
      }
    }
  }
  
  uint8_t EncoderConvertBitToByte(uint8_t *bits, uint8_t length){
    uint8_t val = 0;
    int i;

    for(i=0; i<length; i++)
    {
      val = val*2;
      val = val + bits[i];
    }
    return val;
  }
  
  void DecoderConvertByteToBit(uint8_t byte){
    uint8_t i,mask = 1;
    
    // Extract the bits
    for (i = 0; i < 8; i++) {
      // Mask each bit in the byte and store it
      binarybuffer[7-i] = (byte & (mask << i)) != 0;  /* <<<< need to be fixed (7-i)*/ 
    }     
  }
  
  void DecoderReconstruct(uint8_t *array,uint16_t length){
    uint8_t a,b,i;
    a = array[0];
    b = array[1];
    
    for(i=0; i<length; ++i){
      if(decompressbuffer[i] == 0){
        decodebuffer[i]=a;
      }
      else{
        decodebuffer[i]=b;
      }       
    }
  }
  
  void PrintArray(uint8_t *array, uint16_t length){
    uint8_t i;
    printf("PrintArray\n");
    for(i=0; i<length; ++i){
      printf("%d ",array[i]); 
    }
    printf("\n");
  }
  
  void Decompress(uint8_t *datacompressed, uint8_t dcompLength){
    uint8_t j=2, i,n=0;
    
    /* Convert byte to bit (e.g. 255 to 11111111) 
     * binarybuffer will be updated
     * */
    DecoderConvertByteToBit(datacompressed[j]);
    for(i = 0; i<(dcompLength-1)*8; i++){
      decompressbuffer[i] = binarybuffer[n];
      n++;
      /*To start over with a new byte*/
      if((i+1) % 8 == 0){
        n = 0;
        j++;
        DecoderConvertByteToBit(datacompressed[j]);
      }
    }
    /*Reconstruct corresponding to a and b*/
    DecoderReconstruct(datacompressed,(dcompLength-1)*8);     
  }
  
  inline void compressNextBlock() {
    uint16_t length = BLOCK_SIZE * BLOCK_SIZE;
    uint8_t data[BLOCK_SIZE * BLOCK_SIZE]; // Data of size 16
    
    call BlockReader.readNextBlock(data);
    
    uint8_t i,counter=1,inds=0,p;
    uint8_t q=0;
    uint8_t sendcompressedpackage[2+BLOCK_SIZE]; // TODO: Is it correct?
    uint8_t bits[8] = {1,1,1,1,1,1,1,1};
    uint8_t testbuffer[5] = {1,2,3,4,5};
    float sd,a,b,mean;
    printf("Compress image!!\n");
    /*
     * ENCODER ENCODER ENCODER ENCODER ENCODER ENCODER ENCODER
     */
    /* Calculate mean*/
    mean = Mean(data,length);
    /* Calculate standard deviation*/            
    sd = StandardDeviation(data,length);        
    
    /* number of pixels greater than the mean */
    for(i = 0; i < length; ++i){
      if(data[i]>mean){
        q++;
      }
    }
    /* Reconstruction values a and b */   
    a = mean - sd*SquareRoot((float)q/(float)(length-q));
    b = mean + sd*SquareRoot((float)(length-q)/(float)q);    

    /* convert data array to 1's and 0's */
    EncoderConvertToSingleBit(data,length,mean);
    
    /* store a and b in array */
    sendcompressedpackage[0] = (uint8_t)a;
    sendcompressedpackage[1] = (uint8_t)b;
    /*start position (p=2) for rest of bytes*/
    p = 1;
    
    for(i = 0; i<length; ++i){
      /* buffer that saves the 8 bits that need to be converted to a byte */
      bits[inds]=compressbuffer[i];
      inds++;
      /* to only use 8 bits */
      if(counter%8 == 0){
        /*save the converted bytes in rest of array*/
        p++;
        sendcompressedpackage[p] = EncoderConvertBitToByte(bits,8);
        inds = 0;
      }
      counter++;
    }
    /* SEND ARRAY sendcompressedpackage with length p */
    
    call OutBuffer.writeChunk(sendcompressedpackage, 4); // TODO: Do not use magic number
  }

  command void Compressor.fileBegin(uint16_t imageWidth){
    _imageWidth = imageWidth;
    call BlockReader.prepare(imageWidth, BLOCK_SIZE);
  }

  command void Compressor.compress(bool last){
    while (call BlockReader.hasMoreBlocks()) {
      compressNextBlock();
    }
  }
  
  command uint8_t Compressor.getCompressionType(){
    return COMPRESSION_TYPE_BLOCK_TRUNCATION;
  }
}