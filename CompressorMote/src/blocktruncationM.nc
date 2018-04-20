#include "printf.h"

module blocktruncationM{
	provides interface OnlineCompressionAlgorithm;
	uses interface Leds;
}
implementation{
	uint8_t compressbuffer[16];
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
	  	printf("hello hello hello\n");
	  	for(i = 0; i < length; i++){
	  		printf("%d \n",data[i]);
	  	}

	  	for(i = 0; i < length; i++){
	  		meanvalue = data[i] + meanvalue;
	  		printf("meanvalue %d data %d \n",meanvalue,data[i]);
	  	}


	  	meanvalue = meanvalue/16.0;
	  	printf("meanvalue %f %d\n",meanvalue,meanvalue);
	  	test();
	  	//calculateSD(data);
	  	//printf("\nStandard Deviation = %.6f", calculateSD(data));	  	
  		printfflush();
	}

	command void OnlineCompressionAlgorithm.init(){
		// TODO Auto-generated method stub
	}
	void test(){
		int i = 10;
	}
	void calculateSD(float data[]){
		float sum = 0.0, mean, standardDeviation = 0.0;
		int i;  
		
		for(i=0; i<10; ++i){
			sum += data[i];
		}
		mean = sum/10;
		for(i=0; i<10; ++i){
			standardDeviation += pow(data[i] - mean, 2);
		}
		//return sqrt(standardDeviation/10);
	}	
	
	
}