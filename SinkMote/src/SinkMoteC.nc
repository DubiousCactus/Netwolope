configuration SinkMoteC{
}
implementation{
  components MainC;
  components LedsC;
  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components SinkMoteM;
  components PCFileSenderM;
  
  
  PCFileSenderM.Timeout -> Timer1;
  PCFileSenderM.SerialControl -> Serial;
  PCFileSenderM.SerialPacket -> Serial;
  PCFileSenderM.SerialAMPacket -> Serial;
  PCFileSenderM.SerialSend -> Serial.AMSend;
  PCFileSenderM.SerialReceive -> Serial.Receive; 
  
  SinkMoteM.Boot -> MainC;
  SinkMoteM.Leds -> LedsC;
  SinkMoteM.ErrorTimer -> Timer0;
  SinkMoteM.PCFileSender -> PCFileSenderM;
  SinkMoteM.RadioAMPacket -> Radio;
  SinkMoteM.RadioPacket -> Radio;
}