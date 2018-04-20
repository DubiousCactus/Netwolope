#include "printf.h"
#include <math.h>

module blocktruncationM{
	provides interface OnlineCompressionAlgorithm;
	uses interface Leds;
}
implementation{
	uint8_t compressbuffer[16];
	void test(){
		int i = 10;
	}
	uint16_t powerfunction(uint16_t A, uint16_t B){
		uint16_t ans = A;
		uint16_t i = 1;
		while(i < B){
			ans = ans * A;
			i++;
		}
		return ans;
	}
// Returns floor of square root of x
	uint16_t floorSqrt(uint16_t x)
	{
		uint16_t i = 1, result = 1;
	    // Base cases
	    if (x == 0 || x == 1)
	    return x;
	 
	    // Staring from 1, try all numbers until
	    // i*i is greater than or equal to x.
	    
	    while (result <= x)
	    {
	      i++;
	      result = i * i;
	    }
	    return i - 1;
	}
	
	
	uint16_t calculateSD(uint8_t *data, uint16_t length){
		uint16_t sum = 0, mean, standardDeviation = 0;
		int i;    
		
		for(i=0; i<length; ++i){
			sum += data[i];
			
		}
		mean = sum/length;
		for(i=0; i<length; ++i){
			standardDeviation += powerfunction(data[i] - mean, 2);
			printf("sd %d", standardDeviation);
		}
		return floorSqrt(standardDeviation/10);
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

	command void OnlineCompressionAlgorithm.compress(uint8_t *data, uint16_t length){
		uint8_t i;
		uint16_t meanvalue = 0;
		call Leds.led1On();
	  	printf("Hi I am writing to you from my TinyOS application!!\n");
	  	/*for(i = 0; i < length; i++){
	  		printf("%d \n",data[i]);
	  	}*/

	  	for(i = 0; i < length; i++){
	  		meanvalue = data[i] + meanvalue;
	  		//printf("meanvalue %d data %d \n",meanvalue,data[i]);
	  	}

	  	meanvalue = meanvalue/length;
	  	printf("meanvalue %d\n",meanvalue);
	  	
	  	//calculateSD(data);
	  	printf("\nStandard Deviation = %d value", calculateSD(data,length));	  	
  		printfflush();
	}

	command void OnlineCompressionAlgorithm.init(){
		// TODO Auto-generated method stub
	}
	
	
	
}