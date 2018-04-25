configuration ProgramTestC{
}
implementation{
  components ProgramTestM;
  components MainC;
  components PrintfC;
  components LedsC;
  components new CircularBufferM(1024) as Buffer;
  
  ProgramTestM.Boot -> MainC;
  ProgramTestM.Leds -> LedsC;
  ProgramTestM.BufferReader -> Buffer;
  ProgramTestM.BufferWriter -> Buffer;
  ProgramTestM.BlockReader -> Buffer;
}