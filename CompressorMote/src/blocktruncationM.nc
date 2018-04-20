#include "printf.h"
#include <math.h>

module blocktruncationM{
	provides interface OnlineCompressionAlgorithm;
	uses interface Leds;
}
implementation{
	uint8_t compressbuffer[16];

	uint16_t Powerfunction(uint16_t A, uint16_t B){
		uint16_t ans = A;
		uint16_t i = 1;
		while(i < B){
			ans = ans * A;
			i++;
		}
		return ans;
	}	
	
	uint8_t rootfunction(uint8_t x){
		uint8_t a,b;
		b = x;
		a = x = 0x3f;
		x = b/x;
		a = x = (x+a)>>1;
		x = b/x;
		a = x = (x+a)>>1;
		x = b/x;
		x = (x+a)>>1;
		return(x);
	}
	// Returns floor of square root of x
	float FloorSqrt(float x)
	{
		float i = 1, result = 1;
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
	    return (i - 1);
	}
	float root(float n){
	  float lo = 0, hi = n, mid;
	  int i;
	  for(i = 0 ; i < 1000 ; i++){
	      mid = (lo+hi)/2;
	      if(mid*mid == n) return mid;
	      if(mid*mid > n){
	          hi = mid;
	      }else{
	          lo = mid;
	      }
	  }
	  return mid;
	}	
	
	float Mean(uint8_t *data, uint16_t length){
		uint8_t i;
		float sum = 0,mean = 0;
	  	for(i = 0; i < length; ++i){
	  		sum += data[i];
	  	}

	  	mean = (sum/(float)length);
	  	return mean;
	}
	float StandardDeviation(uint8_t *data, uint16_t length){
		uint16_t standardDeviation = 0;
		uint8_t i;
		float mean;
		mean = Mean(data, length);

		for(i=0; i<length; ++i){
			standardDeviation += Powerfunction(data[i] - mean, 2);
		}
		return root((float)standardDeviation/(float)length);
	}
	
	void ReconstructImage(uint8_t *data,uint16_t length,float meanvalue){
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
		uint8_t q=0;
		float sd,a,b,mean;
		call Leds.led1On();
	  	printf("Hi I am writing to you from my TinyOS application!!\n");

	  	printf("\nMean = %d\n", (uint8_t)Mean(data,length));
	  	printf("\nStandard Deviation = %d\n", (uint8_t)StandardDeviation(data,length));
	  	mean = Mean(data,length);
	  	sd = StandardDeviation(data,length);
	  	
	  	for(i = 0; i < length; ++i){
	  		if(data[i]>mean){
	  			q++;
  			}
	  	}
	  	printf("testing sqrt %d\n",(uint8_t)(FloorSqrt((float)15)*(float)5));
	  	printf("testing sqrt %d\n",(uint8_t)(root((float)15)*(float)5));
	  		  		  	
	  	a = mean - sd*root((float)q/(float)(length-q));
	  	b = mean + sd*(float)root((float)(length-q)/(float)q);

	  	printf("a %d\n",(uint8_t)a);
	  	printf("b %d\n",(uint8_t)b);
	  	ReconstructImage(data,length,mean);
	  	for(i = 0; i < length; ++i){
	  		printf("%d ",compressbuffer[i]);

	  	}	  	
  		printfflush();
	}

	command void OnlineCompressionAlgorithm.init(){
		// TODO Auto-generated method stub
	}
	
	
	
}