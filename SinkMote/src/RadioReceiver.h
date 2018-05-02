#ifndef RADIO_RECEIVER_H
#define RADIO_RECEIVER_H

typedef enum {
  RR_ERR_SEND_FAILED = 1,
  RR_ERR_WRONG_MSG   = 2
} RadioReceiverError;

typedef enum {
    AM_MSG_BEGIN_FILE         = 20,
    AM_MSG_ACK_BEGIN_FILE     = 21,
    AM_MSG_PARTIAL_DATA       = 22,
    AM_MSG_NACK_PARTIAL_DATA  = 23,
    AM_MSG_END_OF_CHUNK       = 24,
    AM_MSG_ACK_END_OF_CHUNK   = 25,
    AM_MSG_RECOVERY           = 26,
    AM_MSG_ACK_RECOVERY       = 27,
    AM_MSG_EOF                = 28,
    AM_MSG_ACK_EOF            = 29,
} MessageType;

typedef enum {
  IDLE,
  READY,
  BEGIN_TRANSFER,
  RECEIVING_CHUNK,
  RECOVERY,
  END_OF_CHUNK,
  END_OF_FILE,
  ERROR
} State;

typedef enum {
  WAITING,
  SENDING,
  RECEIVING
} SubState;

typedef nx_struct {
  nx_uint32_t uncompressedSize;
  nx_uint8_t compressionType;
} BeginFileMsg;

typedef nx_struct {
  nx_uint32_t seq;
} NackMsg;

#endif /* RADIO_RECEIVER_H */
