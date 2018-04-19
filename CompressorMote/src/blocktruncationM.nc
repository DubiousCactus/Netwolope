#include "printf.h"

module blocktruncationM{
	provides interface OnlineCompressionAlgorithm;
	uses interface Leds;
}
implementation{

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
		call Leds.led1On();
	  	printf("Hi I am writing to you from my TinyOS application!!\n");
	  	printf("hello hello hello\n");
	  	for(i = 0; i < length; i++){
	  		printf("%d \n",data[i]);
	  	}
  		printfflush();
	}

	command void OnlineCompressionAlgorithm.init(){
		// TODO Auto-generated method stub
	}
}