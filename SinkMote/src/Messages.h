#ifndef MESSAGES_H
#define MESSAGES_H

enum {
  PARTIAL_DATA_CAPACITY = 60
};

  typedef nx_struct {
    nx_uint8_t type;
    nx_uint32_t name;
    nx_uint32_t size;
  } BeginFileMsg;

  typedef nx_struct {
    nx_uint16_t seqNo;
    nx_uint8_t flags;
    nx_uint8_t dataSize;
    nx_uint8_t data[PARTIAL_DATA_CAPACITY];
  } PartialDataMsg;

  typedef nx_struct {
    nx_uint8_t name;
  } EndOfFileMsg;

#endif /* MESSAGES_H */
