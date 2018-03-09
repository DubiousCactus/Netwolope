#ifndef BLINKTORADIO_H
 #define BLINKTORADIO_H
 
 enum {
   AM_BLINKTORADIO = 6,
   TIMER_PERIOD_MILLI = 1000
 };

typedef nx_struct ReceivePackageMsg {
  nx_uint8_t type; //if type is 00 then its data otherwise it is end of message.
  nx_uint8_t datalength;
  nx_uint8_t data[20];
} ReceivePackageMsg;

 
typedef nx_struct BlinkToRadioMsg {
  nx_uint16_t nodeid;
  nx_uint16_t counter;
} BlinkToRadioMsg;

 #endif
