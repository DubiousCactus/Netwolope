#include "PCFileSender.h"

interface PCFileSender {
  
  /**
   * Initiate a communication line with the PC.
   * The <code>established</code> will be signaled when a 
   * connection is successfully established.
   */
  command void init();
  
  /**
   * Attempts to send partial data to the PC.
   * 
   * @param data  A pointer to a buffer
   * @param size  The length of data to send.
   */
  command void send(uint8_t* data, uint8_t size);
  
  command void sendMessage(message_t* msg, uint8_t payloadSize);
  
  command void sendEOF();
  
  /**
   * Signaled when a connection to the PC is established successfully.
   */
  event void established();
  
  /**
   * Signaled when a communication error occurs.
   * 
   * @param error The error code describing the error.
   */
  event void error(PCFileSenderError error);
  
  /**
   * Signaled when some data has been sent successfully.
   */
  event void sent();
}