#include "RadioHeader.h"
#include "Timer.h"

module RadioSenderM {
  provides interface RadioSender;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation {
  uint16_t currentSequenceNumber = 0;
  nx_uint8_t tracker[DATA_SIZE]; //Used for the receiver to track received packages.
  bool busy = FALSE;
  message_t pkt;
  
  void flipTacker(nx_uint8_t* A) {
    int i;
    for(i = 0; i < DATA_SIZE;i++) {
      if(A[i] == 1) {
        tracker[i] = 1;
      }else{
        tracker[i] = 0;
      }
    }
  }
  
  bool anymissing() {
    bool zero = FALSE;
    bool onesAfterZero = FALSE;
    int i;
    for(i = 0; i < DATA_SIZE;i++) {
      if(tracker[i] == 0) {
        zero = TRUE;
      }else{
        if(zero) {
          onesAfterZero = TRUE;
          }
      }
    }
    return zero && onesAfterZero;
  }
  
  /*findMissingPackage:
   * Returning the missing package ID by looking at the tracker array.
   * */
  uint16_t findMissingPackage() {
    uint16_t i;
    for(i = 0; i < DATA_SIZE;i++) {
      if(tracker[i] == 0) {
        return i;
      }
    }
    return -1;
  }
  
  /*
   * setData:
   * Sets the dataElement in a package equal to the array *d
   * */
  void copyArray(nx_uint8_t* A, nx_uint8_t *B) {
    int i;
    for(i = 0; i < DATA_SIZE;i++) {
      A[i] = B[i];
    }
  }
  
   /*sendOptionPackage:
  * id: unique identification number for the image part.
  * last: Tells the receiver that this is the last part to be send (unless the receives request a previous part.)
  * request: Tells the Sender that a part is missing.
  * This task will send a DataPackage struct, in case of a request for a part the data element will be empty.*/
  void sendOptionPackage(uint8_t last, uint8_t request, uint8_t * data, uint8_t size) {
    uint8_t i;
    if (!busy) {
      DataPackage* DP = (DataPackage*)(call Packet.getPayload(&pkt, sizeof (DataPackage)));
      currentSequenceNumber = findMissingPackage();
      if(currentSequenceNumber != -1) {
        DP->sequenceNumber = currentSequenceNumber;
        DP->last = last;
        DP->request = request;
        DP->dataSize = size;
        for (i = 0; i < size; i++) {
          DP->data[i] = data[i];
        }
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DataPackage)) == SUCCESS) {
         busy = TRUE;     
        }
      }
    }
  }

  event void AMSend.sendDone(message_t *msg, error_t error) {
    if (&pkt == msg) {
      tracker[currentSequenceNumber] = 1;
      busy = FALSE;
    }
    signal RadioSender.sendDone();
  }


  event void AMControl.stopDone(error_t error) {
  }


  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      signal RadioSender.readyToSend();
    }
    else {
       call AMControl.start();
    }
  }
  
  
  void receiveRequest(DataPackage* package) {
    flipTacker(package->data);
  }
  
  event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len) {
      if (len == sizeof(DataPackage)) {
        DataPackage* package = (DataPackage*)payload;
        if(package->request == 1) {
          receiveRequest(package);
        }
        }
        return msg;
    }


  command void RadioSender.send(uint8_t last, uint8_t request, uint8_t * data, uint8_t size) {
    sendOptionPackage(last, request, data, size);
  }
  
  void setTracker() {
    int i;
    for(i = 0; i < DATA_SIZE;i++) {
      tracker[i] = 0;
      }
  }
  
  command void RadioSender.start() {
    setTracker();
    call AMControl.start();
  }

}
