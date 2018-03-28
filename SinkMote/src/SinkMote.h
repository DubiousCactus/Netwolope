#ifndef SINK_MOTE_H
#define SINK_MOTE_H

#include "message.h"


typedef nx_struct PartialDataMsgT {
  nx_uint8_t data[50];
} PartialDataMsg;


enum {
  AM_TEST_SERIAL_MSG = 0x89,
  AM_PARTIAL_DATA_MSG = 0x42,
};


#endif /* SINK_MOTE_H */
