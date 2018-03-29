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
  components PCCom;
  
  
  PCCom.Leds -> LedsC;
  PCCom.ErrorTimer -> Timer0;
  PCCom.Timeout -> Timer1;
  
  PCCom.SerialControl -> Serial;
  PCCom.SerialPacket -> Serial;
  PCCom.SerialAMPacket -> Serial;
  PCCom.SerialSend -> Serial.AMSend;
  PCCom.SerialReceive -> Serial.Receive; 
  
  SinkMoteM.Boot -> MainC;
  SinkMoteM.Leds -> LedsC;
  SinkMoteM.PCConnection -> PCCom;
}