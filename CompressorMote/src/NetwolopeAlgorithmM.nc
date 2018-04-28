#include "printf.h"
#include <math.h>

module NetwolopeAlgorithmM{
    provides interface OnlineCompressionAlgorithm as Compressor;
    uses interface CircularBufferWriter as OutBuffer;
    uses interface CircularBufferReader as InBuffer;
}
implementation{

  enum {
    BLOCK_SIZE = 4,
  };
  uint16_t _imageWidth;
  

    void toBitArray(uint8_t n,uint8_t * out, uint8_t length){
        int c;
        int k;
        int i = 0;
        for (c = length-1; c >= 0; c--)
        {
            k = n >> c;
            if (k & 1){
              out[i] = 1;
            }
            else{
              out[i] = 0;
            }
            i++;
        }
    }
    void ConcatenateArrays(uint8_t * inA, uint8_t * inB, uint8_t * out){
        int i;
        for(i = 0; i <= 3; i++){
            out[i] = inA[i];
        }
        for(i = 0; i <= 3; i++){
            out[i+4] = inB[i];
        }
    }
    uint8_t bitarrayToInt(uint8_t* inA,uint8_t length){
        int i;
        uint8_t res = 0;
        for(i = 0; i < length; i++){
            res = 2 * res + inA[i];
        }
        return res;
    }
    
    
    
    
    void compress(){
        uint8_t outA[4];
        uint8_t outB[4];
        uint8_t outC[8];
        uint8_t data1, data2;
        double res;

          while (call InBuffer.available() > 1) {
            
            call InBuffer.read(&data1);
            call InBuffer.read(&data2);
          
            res = (double)(data1/16);
            res = res < 15 && res > 0.5? (uint8_t)(res+0.5): res;
            toBitArray((uint8_t)(res),outA,4); 

            res = (double)(data2/16);
            res = res < 15 && res > 0.5? (uint8_t)(res+0.5): res;
            toBitArray((uint8_t)(res),outB,4);

            ConcatenateArrays(outA,outB,outC);

            call OutBuffer.write(bitarrayToInt(outC,8));
        }
    }
    
    
  command void Compressor.fileBegin(uint16_t imageWidth){
    _imageWidth = imageWidth;
  }

  command void Compressor.compress(bool last){
    compress();
    
    signal Compressor.compressed();
  }
  
  command uint8_t Compressor.getCompressionType(){
    return COMPRESSION_TYPE_NETWOLOPE;
  }
}