#include "DataPackageCommunication.h"
#include "Timer.h"
module DataPackageCommunication{
   provides interface IDataPackageCommunication;
   uses interface Packet;
   uses interface AMPacket;
   uses interface AMSend;
   uses interface Receive;
   uses interface Leds;
   //uses interface Timer<TMilli> as Timer0;
   uses interface SplitControl as AMControl;
}
implementation{
    uint16_t currentSequenceNumber = 0;
	nx_uint8_t tracker[DATA_SIZE]; //Used for the receiver to track received packages.
	bool busy = FALSE;
    message_t pkt;
    //nx_uint8_t data[DATA_SIZE] = {0,0,0,0,0,0,0,0,0,0};
    bool SENDER = TRUE;
    
	/* requestDataOnId : 
	 * id: id for the requested image part
	 * Returns a part of the image, id corresponds to the index of the part.
	 * Meaning, id will determine what part of the image to return, since the image is split into multiple compressed parts in order to be stored on the telosB. */
	
	/*void requestDataOnId(int id){
		data[1] = 30;
	}*/
	
	void flipTacker(nx_uint8_t* A){
		int i;
		for(i = 0; i < DATA_SIZE;i++){
			if(A[i] == 1){
				tracker[i] = 1;
			}else{
				tracker[i] = 0;
			}
		}
	}
	
	bool anymissing(){
		bool zero = FALSE;
		bool onesAfterZero = FALSE;
		int i;
		for(i = 0; i < DATA_SIZE;i++){
			if(tracker[i] == 0){
				zero = TRUE;
			}else{
				if(zero){
					onesAfterZero = TRUE;
					}
			}
		}
		return zero && onesAfterZero;
	}
	
	/*findMissingPackage:
	 * Returning the missing package ID by looking at the tracker array.
	 * */
	uint16_t findMissingPackage(){
		uint16_t i;
		for(i = 0; i < DATA_SIZE;i++){
			if(tracker[i] == 0){
				return i;
			}
		}
		return -1;
	}
	
 /*Used for debugging*/
     void blink(int led){     	
     	int i;
     	call Leds.led0Off();
     	call Leds.led1Off();
     	call Leds.led2Off();
     	for(i = 0; i < TIMEOUT;i++){}i=0;
		switch(led){
			case 0:
				call Leds.led0Toggle();
				for(i = 0; i < TIMEOUT;i++)
				call Leds.led0Toggle();
				break;
			case 1:
				call Leds.led1Toggle();
				for(i = 0; i < TIMEOUT;i++)
				call Leds.led1Toggle();
				break;
			case 2:
				call Leds.led2Toggle();
				for(i = 0; i < TIMEOUT;i++)
				call Leds.led2Toggle();
				break;
			case 3:
				call Leds.led0Toggle();
				call Leds.led1Toggle();
				for(i = 0; i < TIMEOUT;i++)
				call Leds.led1Toggle();
				call Leds.led0Toggle();
				break;
			case 4:
				call Leds.led0Toggle();
				call Leds.led2Toggle();
				for(i = 0; i < TIMEOUT;i++)
				call Leds.led2Toggle();
				call Leds.led0Toggle();
				break;
			case 5:
				call Leds.led1Toggle();
				call Leds.led2Toggle();
				for(i = 0; i < TIMEOUT;i++)
				call Leds.led2Toggle();
				call Leds.led1Toggle();
				break;
			case 6:
				call Leds.led0Toggle();
				call Leds.led1Toggle();
				call Leds.led2Toggle();
				for(i = 0; i < TIMEOUT;i++)
				call Leds.led2Toggle();
				call Leds.led1Toggle();
				call Leds.led0Toggle();
				break;
			}
     	call Leds.led0Off();
     	call Leds.led1Off();
     	call Leds.led2Off();
     	for(i = 0; i < TIMEOUT;i++){}i=0;
	}
	
	/*
	 * setData:
	 * Sets the dataElement in a package equal to the array *d
	 * */
	void copyArray(nx_uint8_t* A, nx_uint8_t *B){
		int i;
		for(i = 0; i < DATA_SIZE;i++){
			A[i] = B[i];
		}
	}
	
 	/*sendOptionPackage:
     * id: unique identification number for the image part.
     * last: Tells the receiver that this is the last part to be send (unless the receives request a previous part.)
     * request: Tells the Sender that a part is missing.
     * This task will send a DataPackage struct, in case of a request for a part the data element will be empty.*/
    void sendOptionPackage(nx_bool *last, nx_bool* request, nx_uint8_t * data, nx_uint8_t size){
    	if (!busy) {
	    	DataPackage* DP = (DataPackage*)(call Packet.getPayload(&pkt, sizeof (DataPackage)));
			currentSequenceNumber = findMissingPackage();
			if(currentSequenceNumber != -1){
				DP->sequenceNumber = currentSequenceNumber;
				DP->last = last;
				DP->request = request;
				DP->dataSize = size;
				if(request == 0){
					blink(2);
					//requestDataOnId(currentId);
					copyArray(DP->data, data);
				}else{
					//blink(3);
					copyArray(DP->data, tracker);
				}
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DataPackage)) == SUCCESS) {
			      busy = TRUE;		 
					if(SENDER){
						blink(1);
					}  
			    }
		    }
	    }
	}
	
	/*sendToPC:
	 * Will send the data d to the computer for it to decompress and make the image.*/
	void sendToPC(nx_uint8_t* d){
		
	}
	
	/*void start(bool IsSender){
		SENDER = IsSender;
		//call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
     	call AMControl.start();
	}*/
   /*event void Boot.booted() {
     call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
     call AMControl.start();
   }*/

/*
   event void Timer0.fired() {
   	if(TOS_NODE_ID == 1){
   		sendOptionPackage(0,0);
   		SENDER = TRUE;
   	}else{
   		SENDER = FALSE;
   	}
   }
*/
	event void AMSend.sendDone(message_t *msg, error_t error){
		if (&pkt == msg) {
		  if(SENDER){
			blink(0); 
			tracker[currentSequenceNumber] = 1;
		  } 
	      busy = FALSE;
	    }
	    signal IDataPackageCommunication.sendDone();
	}

	event void AMControl.stopDone(error_t error){
	}

	event void AMControl.startDone(error_t error){
		if (error == SUCCESS) {
			signal IDataPackageCommunication.readyToSend();
      		//call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
    	}
    	else {
      		call AMControl.start();
    	}
	}
	
	void receiveRequest(DataPackage* package){
		blink(6);
		flipTacker(package->data);
	}
	
	void receiveASyncPackage(DataPackage* package){
		tracker[package->sequenceNumber] = 1;
	    sendOptionPackage(FALSE,TRUE,tracker,DATA_SIZE);
	}
	
	void receivePackage(DataPackage* package){
		//signal IDataPackageCommunication.receivedData(package->data, package->dataSize);
		sendToPC(package->data);
		blink(package->sequenceNumber%7);
		tracker[package->sequenceNumber] = 1;
	}
	
	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
			if (len == sizeof(DataPackage)) {
		    	DataPackage* package = (DataPackage*)payload;
		    	if(package->request == 1 && SENDER){
		    		receiveRequest(package);
		    	}
		    	else if(package->request == 0 && !SENDER){
	    			receivePackage(package);
	    			if(package->sequenceNumber != findMissingPackage()){
	    				receiveASyncPackage(package);
	    			}
		    	}
		  	}
		  	return msg;
		}


	command void IDataPackageCommunication.send(u_int8_t last, u_int8_t request, nx_uint8_t * data, nx_uint8_t size){
		sendOptionPackage(last==1,request==1,data,size);
	}
	
	void setTracker(){
		int i;
		for(i = 0; i < DATA_SIZE;i++){
			tracker[i] = 0;
			}
	}
	
	command void IDataPackageCommunication.start(u_int8_t isSender){
		setTracker();
		if(isSender){
			SENDER == TRUE;
		}
     	call AMControl.start();
     }
	/*command void startlistening(u_int8_t last){
		
	}
	command void stopListening(u_int8_t last){
		
	}*/

}