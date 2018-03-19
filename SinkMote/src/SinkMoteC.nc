configuration SinkMoteC{
}
implementation{
  components MainC;
  components LedsC;
  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;
  components SinkMoteM;

  SinkMoteM.Boot -> MainC;
  SinkMoteM.Leds -> LedsC;
	
  SinkMoteM.SerialControl -> Serial;
  SinkMoteM.SerialPacket -> Serial;
  SinkMoteM.SerialAMPacket -> Serial;
  SinkMoteM.SerialSend -> Serial;
  
  SinkMoteM.RadioControl -> Radio;
  SinkMoteM.RadioPacket -> Radio;
  SinkMoteM.RadioAMPacket -> Radio;
  //SinkMoteM.RadioSend -> Radio;
  //SinkMoteM.RadioReceive -> Radio.Receive;
  //SinkMoteM.RadioSnoop -> Radio.Snoop;
}