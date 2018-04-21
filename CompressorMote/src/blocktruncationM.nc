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
			standardDeviation += Powerfunction(data[i] - (uint8_t)mean, 2);
		}
		printf("Sd %d\n",(uint16_t)standardDeviation);
		return root((float)standardDeviation/(float)length);
	}
	
	void ConvertToSingleBit(uint8_t *data,uint16_t length,float meanvalue){
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
	
	uint8_t ConvertBitToByte(uint8_t *bits, uint8_t length){
	  uint8_t val = 0;
	  int i;

		for(i=0; i<length; i++)
		{
		  val = val*2;
		  val = val + bits[i];
		}
		printf("val %d\n",val);	  
		//compressbuffer[i]
		return val;
	}
	void PrintArray(uint8_t *array, uint8_t length){
		uint8_t i;
		printf("PrintArray\n");
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

	command void OnlineCompressionAlgorithm.compress(uint8_t *data, uint16_t length){
		uint8_t i,counter=1,inds=0,k,p;
		uint8_t q=0;
		uint8_t sendcompressedpackage[length];
		uint8_t bits[8] = {1,1,1,1,1,1,1,1};
		float sd,a,b,mean;
		call Leds.led1On();
	  	printf("Compress image!!\n");
	  	
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
	  	a = mean - sd*root((float)q/(float)(length-q));
	  	b = mean + sd*(float)root((float)(length-q)/(float)q);
	  	
	  	/* convert data array to 1's and 0's */
	  	ConvertToSingleBit(data,length,mean);
	  	
	  	/* store a and b in array */
	  	sendcompressedpackage[0] = (uint8_t)a;
  		sendcompressedpackage[1] = (uint8_t)b;
  		p = 2;
  		/*finish the encoding*/
	  	for(i = 0; i<length; ++i){
	  		/* buffer that saves the 8 bits that need to be converted to a byte */
	  		bits[inds]=compressbuffer[i];
	  		inds++;
	  		/* to only use 8 bits */
	  		if(counter%8 == 0){
	  			//for(k=0; k<8; k++){
	  				//printf("bits %d\n",bits[k]);
  				//}
  				//printf("index counter %d\n",i);
  				/*save the converted bytes in rest of array*/
	  			sendcompressedpackage[p] = ConvertBitToByte(bits,8);
	  			//printf("compress: %d \n",sendcompressedpackage[p]);
	  			p++;
	  			inds = 0;
  			}
  			
  			printf("p %d \n",p);
  			for(i=0;i<p; i++){
  				printf("%d ", sendcompressedpackage[p]);
			}
			/*
			printf("\n");
  			PrintArray(sendcompressedpackage, p-1);*/
	  	}	  
	  	/*printf("sd %d\n",(uint8_t)sd);
	  	printf("testing sqrt %d\n",(uint8_t)(FloorSqrt((float)15)*(float)5));
	  	printf("testing sqrt %d\n",(uint8_t)(root((float)15)*(float)5));
	  	printf("a %d\n",(uint8_t)a);
	  	printf("b %d\n",(uint8_t)b);	  	
	  	for(i = 0; i < length; ++i){
	  		printf("%d ",compressbuffer[i]);
	  	}*/
	  	
  		printfflush();
	}
	

	command void OnlineCompressionAlgorithm.init(){
		// TODO Auto-generated method stub
	}
	
	
	
}