#define NEW_PRINTF_SEMANTICS

#include "printf.h"

configuration SinkMoteC{
}
implementation{
  components MainC;
  components PrintfC;
  components LedsC;
  components ActiveMessageC as Radio;
  
  components SerialActiveMessageC as Serial;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components SinkMoteM;
  components PCFileSenderM;
  components RadioReceiverM;
  
  PCFileSenderM.Timeout -> Timer1;
  PCFileSenderM.SerialControl -> Serial;
  PCFileSenderM.SerialPacket -> Serial;
  PCFileSenderM.SerialAMPacket -> Serial;
  PCFileSenderM.SerialSend -> Serial.AMSend;
  PCFileSenderM.SerialReceive -> Serial.Receive;
  
  RadioReceiverM.Packet -> Radio;
  RadioReceiverM.AMPacket -> Radio;
  RadioReceiverM.RadioSend -> Radio.AMSend;
  RadioReceiverM.RadioReceive -> Radio.Receive;
  RadioReceiverM.RadioControl -> Radio;
  
  SinkMoteM.Boot -> MainC;
  SinkMoteM.Leds -> LedsC;
  SinkMoteM.ErrorTimer -> Timer0;
  SinkMoteM.PCFileSender -> PCFileSenderM;
  SinkMoteM.RadioReceiver -> RadioReceiverM;
}
