#include "RadioHeader.h"

configuration SinkMoteC{
}
implementation{
  components MainC;
  components LedsC;
  components ActiveMessageC as Radio;
  components new AMSenderC(COMMUNICATION_ADDRESS);
  components new AMReceiverC(COMMUNICATION_ADDRESS);
  
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
  
  RadioReceiverM.Packet -> AMSenderC;
  RadioReceiverM.AMPacket -> AMSenderC;
  RadioReceiverM.AMSend -> AMSenderC;
  RadioReceiverM.Receive -> AMReceiverC;
  RadioReceiverM.AMControl -> Radio;
  
  SinkMoteM.Boot -> MainC;
  SinkMoteM.Leds -> LedsC;
  SinkMoteM.ErrorTimer -> Timer0;
  SinkMoteM.PCFileSender -> PCFileSenderM;
  SinkMoteM.RadioReceiver -> RadioReceiverM;
}