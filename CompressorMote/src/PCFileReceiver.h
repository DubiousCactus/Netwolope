#ifndef PCFILE_SENDER_H
#define PCFILE_SENDER_H

typedef enum {
  /**
   * Indicates a programmer error. This error should
   * not happen.
   */
  PCC_ERR_PROGRAMMER = 20,
  
  /**
   * Initialisation of the serial interface failed.
   */
  PCC_ERR_SERIAL_INIT_FAILED,
  
  /**
   * Sending data to the PC failed.
   */
  PCC_ERR_SEND_FAILED,
  
  /**
   * Packet received from the PC is dropped.
   */
  PCC_ERR_PACKET_DROPPED
} PCFileSenderError;

#endif /* PCFILE_SENDER_H */
