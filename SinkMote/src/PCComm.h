#ifndef PCCOMM_H
#define PCCOMM_H

enum {
  AM_TRANSMIT_BEGIN_MSG = 0x40,
  AM_TRANSMIT_BEGIN_ACK_MSG = 0x41,
  AM_PARTIAL_DATA_MSG = 0x42,
  AM_TRANSMIT_END_MSG = 0x43
};

typedef enum {
  STATE_BEGIN = 0,
  STATE_SENDING_START_REQUEST = 1,
  STATE_WAITING_START_RESPONSE = 2,
  STATE_ESTABLISHING = 3,
  STATE_ESTABLISHED = 4
} ConnectionState;

typedef nx_struct TransmitBeginMsg {
  nx_uint8_t bufferSize;
} TransmitBeginMsg;


typedef enum {
  PC_CONN_ERROR_UNKNOWN = 0,
  PC_CONN_UNEXPECTED_ERROR = 1
} PcCommunicationError;


#endif /* PCCOMM_H */
