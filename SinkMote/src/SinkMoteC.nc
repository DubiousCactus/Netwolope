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

  SinkMoteM.Boot -> MainC;
  SinkMoteM.Leds -> LedsC;
  SinkMoteM.ErrorTimer -> Timer0;
  SinkMoteM.SerialTimer -> Timer1;
	
  SinkMoteM.SerialControl -> Serial;
  SinkMoteM.SerialPacket -> Serial;
  SinkMoteM.SerialAMPacket -> Serial;
  SinkMoteM.SerialSend -> Serial.AMSend;
  
  SinkMoteM.RadioControl -> Radio;
  SinkMoteM.RadioPacket -> Radio;
  SinkMoteM.RadioAMPacket -> Radio;
  //SinkMoteM.RadioSend -> Radio;
  //SinkMoteM.RadioReceive -> Radio.Receive;
  //SinkMoteM.RadioSnoop -> Radio.Snoop;
}