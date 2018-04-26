#include "printf.h"
#include <math.h>

module NetwolopeAlgorithmM{
	provides interface OnlineCompressionAlgorithm;
	uses interface Leds;
}
implementation{
	/**
	 * This Compression will do the following step
	 * 1. iterate though each data element
	 * 2. for each element devide the data element by 16.
	 * 3. this gives a range between 0 - 15 for each data element.
	 * 4. each data element can maximum be a binary value of 11111111
	 * 5. devide teh value by 16 gives a max binary value of 1111
	 * 6. iterate though every secound data element and concadinate on their 4 bit sequences
	 */
	void PrintArray(uint8_t *array, uint16_t length){
		uint8_t i;
		for(i=0; i<length; ++i){
			printf("%d ",array[i]);	
		}
		printf("\n");
	}

	
	command void OnlineCompressionAlgorithm.fileEnd(){
		// TODO Auto-generated method stub
	}

	command uint8_t OnlineCompressionAlgorithm.getCompressionType(){
		return 1;
	}

	command void OnlineCompressionAlgorithm.fileBegin(uint32_t totalLength){
		// TODO Auto-generated method stub
	}

	void toBitArray(unsigned int n,uint8_t * out, unsigned int length){
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
		printf("outA: %d\n",((bitarrayToInt(oA,4)+1)*16)-1);
		printf("outB: %d\n",((bitarrayToInt(oB,4)+1)*16)-1);
		
	}
	
	
	command void OnlineCompressionAlgorithm.compress(uint8_t *data, uint16_t length){
		int i;
		uint8_t outA[4];
		uint8_t outB[4];
		uint8_t outC[8];
		uint8_t oA;
		uint8_t oB;
		uint8_t A = 0;
		for(i = 0; i < length; ++i){
			//COMPRESSION PART
			printf("COMPRESSING:\n");
			printf("original1: %d \n",data[i]);
			printf("original1 divided: %d \n",(int)(data[i]/15.5f)-1);
			printf("original2: %d \n",data[i+1]);
			printf("original2 divided: %d \n",(int)(data[i+1]/15.5f)-1);
			toBitArray((data[i]/15.5f)-1,outA,4); //LOOK AT THIS FLOAT IT DOES NOT WORK
			PrintArray(outA, 4);
			++i;
			toBitArray((data[i]/15.5f)-1,outB,4); //LOOK AT THIS FLOAT IT DOES NOT WORK
			PrintArray(outB, 4);
			ConcatenateArrays(outA,outB,outC);
			PrintArray(outC, 8);
			A = bitarrayToInt(outC,8);
			printf("value: %d \n",A);
			//DECOMPRESSION PART
			printf("DECOMPRESSING:\n");
			oneToTwo(A,oA,oB);
		    printf("\n");
		}
		printfflush();
	}
	

	command void OnlineCompressionAlgorithm.init(){
		// TODO Auto-generated method stub
	}
	
	
	
}