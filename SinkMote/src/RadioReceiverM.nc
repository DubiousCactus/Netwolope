#include "RadioHeader.h"
#include "Timer.h"
module RadioReceiverM{
  provides interface RadioReceiver;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation{
  uint16_t currentSequenceNumber = 0;
  nx_uint8_t tracker[DATA_SIZE]; //Used for the receiver to track received packages.
  bool busy = FALSE;
  message_t pkt;
  
  uint32_t setBit(uint32_t bitMask, uint8_t position) {
    return bitMask | (1 << position);
  }

  uint8_t getBit(uint32_t bitMask, uint8_t position) {
    return (uint8_t)(bitMask & (1 << position)) >> position;
  }

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
  
  void sendOptionPackage(nx_uint8_t last, nx_uint8_t request, nx_uint8_t * data, nx_uint8_t size){
   if (!busy) {
    DataPackage* DP = (DataPackage*)(call Packet.getPayload(&pkt, sizeof (DataPackage)));
    currentSequenceNumber = findMissingPackage();
    if(currentSequenceNumber != -1){
      DP->sequenceNumber = currentSequenceNumber;
      DP->last = last;
      DP->request = request;
      DP->dataSize = size;
      copyArray(DP->data, tracker);
      if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DataPackage)) == SUCCESS) {
       busy = TRUE;    
      }
    }
   }
  }

  event void AMSend.sendDone(message_t *msg, error_t error){
   if (&pkt == msg) {
    busy = FALSE;
   }
  }


  event void AMControl.stopDone(error_t error){
  }


  event void AMControl.startDone(error_t error){
   if (error == SUCCESS) {
    signal RadioReceiver.readyForReceive();
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
   signal RadioReceiver.receivedData((uint8_t*)package->data, (uint8_t)package->dataSize);
   blink(package->sequenceNumber%7);
   tracker[package->sequenceNumber] = 1;
  }
  
  
  event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
    if (len == sizeof(DataPackage)) {
      DataPackage* package = (DataPackage*)payload;
      if(package->request == 0){
       blink(0);
       receivePackage(package);
       if(package->sequenceNumber != findMissingPackage()){
        receiveASyncPackage(package);
       }
      }
      }
      return msg;
   }


  void setTracker(){
    int i;
    for(i = 0; i < DATA_SIZE;i++){
      tracker[i] = 0;
    }
  }
  
  command void RadioReceiver.start(){
    setTracker();
    call AMControl.start();
  }

}