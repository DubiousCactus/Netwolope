#include "PCFileReceiver.h"

/**
 * Communicates with the PC to receive file content.
 */
interface PCFileReceiver{
  /**
   * Intialises the serial communication and signales <code>initDone()</code> 
   * once it is complete.
   */
  command void init();
  
  /**
   * Sends an ACK message to the PC indicating that the mote
   * is ready to receive more data.
   */
  command void receiveMore();
  
  /**
   * Sends an ACK message to the PC indicating that the mote
   * is ready to receive the file.
   */
  command void sendFileBeginAck();
  
  /**
   * Signalled when serial communication is ready.
   */
  event void initDone();
  
  /**
   * Signalled when the PC intends to send a file. Note 
   * <code>sendFileBeginAck()</code> must be called to let
   * PC proceed sending data to the mote.
   */
  event void fileBegin(uint16_t width);
  
  /**
   * Signalled when the mote has received data from the PC.
   * Call <code>receiveMore()</code> to let PC proceed sending 
   * more data.
   */
  event void receivedData();
  
  /**
   * Signalled when PC has notified the mote that the file
   * contents have been sent successfully. An ACK message
   * is automatically sent back.
   */
  event void fileEnd();
  
  /**
   * Signalled when an error occurred in the model.
   */
  event void error(PCFileReceiverError error);
}