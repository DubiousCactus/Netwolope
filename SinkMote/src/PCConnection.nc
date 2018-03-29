#include "PCComm.h"

interface PCConnection {
  
  /**
   * Initiate a communication line with the PC.
   * The <code>established</code> will be signaled when a 
   * connection is successfully established.
   */
  command void init();
  
  /**
   * Signaled when a connection to the PC is established successfully.
   */
  event void established();
  
  /**
   * Signaled when a communication error occurs.
   * 
   * @param error The error code describing the error.
   */
  event void error(PcCommunicationError error);
}