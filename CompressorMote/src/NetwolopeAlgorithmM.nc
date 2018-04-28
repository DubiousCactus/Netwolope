#include "printf.h"
#include <math.h>

module NetwolopeAlgorithmM{
    provides interface OnlineCompressionAlgorithm as Compressor;
    uses interface CircularBufferWriter as OutBuffer;
    uses interface CircularBufferBlockReader as InBuffer;
}
implementation{

  enum {
    BLOCK_SIZE = 4,
  };
  uint16_t _imageWidth;
  
    void PrintArray(uint8_t *array, uint16_t length){
        uint8_t i;
        for(i=0; i<length; ++i){
            printf("%d ",array[i]); 
        }
        printf("\n");
    }

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
    
    void oneToTwo(uint8_t inA, uint8_t* outA, uint8_t* outB){
        int i;
        uint8_t iA[8];
        uint8_t oA[4];
        uint8_t oB[4];
        
        printf("\ninA is: %d\n",inA);
        toBitArray(inA,iA,8);
        PrintArray(iA, 8);
        
        for(i = 0; i <= 3; i++){
            oA[i] = iA[i];
        }
        for(i = 0; i <= 3; i++){
            oB[i] = iA[i+4];
        }
        PrintArray(oA,4);
        PrintArray(oB,4);
        //printf("outA: %d\n",((bitarrayToInt(oA,4)+1)*16)-1);
        //printf("outB: %d\n",((bitarrayToInt(oB,4)+1)*16)-1);
        //REMEMBER TO PLUS THE FINAL VALUE WITH 1
        
    }
    
    
    void compress(){
        int i;
        uint8_t data[BLOCK_SIZE * BLOCK_SIZE];
        uint8_t outA[4];
        uint8_t outB[4];
        uint8_t outC[8];
        double res;
        //uint8_t oA;
        //uint8_t oB;
        call InBuffer.readNextBlock(data);
        for(i = 0; i < BLOCK_SIZE*BLOCK_SIZE; ++i){
            //COMPRESSION PART
            printf("COMPRESSING:\n");
            printf("original1: %d \n",data[i]);
            printf("original1 divided: %d \n",(int)(data[i]/15.5f)-1);
            printf("original2: %d \n",data[i+1]);
            printf("original2 divided: %d \n",(int)(data[i+1]/15.5f)-1);
            //toBitArray((uint8_t)(data[i]/15.5f)-1,outA,4); //LOOK AT THIS FLOAT IT DOES NOT WORK
            res = (double)(data[i]/16);
            res = res < 15 && res > 0.5? (uint8_t)(res+0.5): res;
            toBitArray((uint8_t)(res),outA,4); //LOOK AT THIS FLOAT IT DOES NOT WORK
            PrintArray(outA, 4);
            ++i;
            //toBitArray((uint8_t)(data[i]/15.5f)-1,outB,4); //LOOK AT THIS FLOAT IT DOES NOT WORK
            res = (double)(data[i]/16);
            res = res < 15 && res > 0.5? (uint8_t)(res+0.5): res;
            toBitArray((uint8_t)(res),outB,4); //LOOK AT THIS FLOAT IT DOES NOT WORK
//            outB = outB < 15 && outB > 0? (uint8_t)(outB-0.5f): outB;
            PrintArray(outB, 4);
            ConcatenateArrays(outA,outB,outC);
            PrintArray(outC, 8);
            printf("value: %d \n",bitarrayToInt(outC,8));
            call OutBuffer.write(bitarrayToInt(outC,8));
            //DECOMPRESSION PART
            //printf("DECOMPRESSING:\n");
            //oneToTwo(A,oA,oB);
            //printf("\n");
            printfflush();
        }
        //call OutBuffer.writeChunk(dataCompressed, 8);
    }
    
    
  command void Compressor.fileBegin(uint16_t imageWidth){
    _imageWidth = imageWidth;
    call InBuffer.prepare(imageWidth, BLOCK_SIZE);
  }

  command void Compressor.compress(bool last){
    while (call InBuffer.hasMoreBlocks()) {
        compress();
    }
    signal Compressor.compressed();
  }
  
  command uint8_t Compressor.getCompressionType(){
    return COMPRESSION_TYPE_NETWOLOPE;
  }
}