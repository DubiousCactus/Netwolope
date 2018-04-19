#ifndef PCFILE_RECEIVER_H
#define PCFILE_RECEIVER_H

typedef enum {
  /**
   * Expected call a call to <code>.receiveMore</code>
   * but did not received
   */
  PFR_ERR_EXPECTED_RECEIVE_MORE = 2,
  
  /**
   * Indicates a programmer error. This error should
   * not happen.
   */
  PFR_ERR_PROGRAMMER,
  
  /**
   * Initialisation of the serial interface failed.
   */
  PFR_ERR_SERIAL_INIT_FAILED,
  
  /**
   * Sending data to the PC failed.
   */
  PFR_ERR_SEND_FAILED,
  
  /**
   * Packet received from the PC is dropped.
   */
  PFR_ERR_PACKET_DROPPED
} PCFileReceiverError;

#endif /* PCFILE_RECEIVER_H */
