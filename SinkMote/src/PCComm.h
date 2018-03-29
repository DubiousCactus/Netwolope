#ifndef PCCOMM_H
#define PCCOMM_H

enum {
  AM_TRANSMIT_BEGIN_MSG = 0x40,
  AM_TRANSMIT_BEGIN_ACK_MSG = 0x41,
  AM_PARTIAL_DATA_MSG = 0x42,
  AM_TRANSMIT_END_MSG = 0x43
};

typedef nx_struct TransmitBeginMsg {
  nx_uint8_t bufferSize;
} TransmitBeginMsg;

typedef nx_struct PartialDataMsg {
  nx_uint8_t size;
  nx_uint8_t data[49];
} PartialDataMsg;

typedef enum {
  PC_CONN_ERROR_UNKNOWN,
  PC_CONN_UNEXPECTED_ERROR,
  PC_CONN_NOT_CONNECTED,
  PC_CONN_ERR_DISCONNECTED
} PcCommunicationError;


#endif /* PCCOMM_H */
