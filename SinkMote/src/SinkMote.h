#ifndef SINK_MOTE_H
#define SINK_MOTE_H

#include "message.h"


typedef nx_struct PartialDataMsgT {
  nx_uint8_t data[50];
} PartialDataMsg;


#endif /* SINK_MOTE_H */
