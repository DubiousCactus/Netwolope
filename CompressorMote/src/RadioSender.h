#ifndef RADIO_SENDER_H
#define RADIO_SENDER_H

typedef enum {
  RS_ERR_INIT_FAILED = 2,
  RS_ERR_INVALID_STATE,
  RS_ERR_PROGRAMMER,
  RS_ERR_SEND_FAILED,
} RadioSenderError;

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

  BUFFER_CAPACITY = 128,
  PACKET_CAPACITY = 64
} MessageType;

typedef enum {
  IDLE,
  READY,
  BEGIN_TRANSFER,
  SENDING_CHUNK,
  RECOVERY,
  END_OF_CHUNK,
  END_OF_FILE,
  ERROR
} State;

typedef enum {
  SENDING,
  RECEIVING
} SubState;

typedef nx_struct {
  nx_uint32_t uncompressedSize;
  nx_uint8_t compressionType;
} BeginFileMsg;

typedef nx_struct {
  nx_uint32_t length;
} AckMsg;

typedef nx_struct {
  nx_uint8_t data[PACKET_CAPACITY];
} PartialDataMsg;

#endif /* RADIO_SENDER_H */
