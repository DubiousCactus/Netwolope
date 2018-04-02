#include "StorageVolumes.h"

configuration ProgramC{
}
implementation{
  components MainC;
  components LedsC;
  components ProgramM;
  components SerialActiveMessageC as Serial;
  components new BlockStorageC(VOLUME_BLOCKTEST) as BlockStorage;
  components new TimerMilliC() as Timer0;

  components PCConnectionM;
  //components FlashStorageImplM;

  PCConnectionM.SerialControl -> Serial;
  PCConnectionM.SerialPacket -> Serial;
  PCConnectionM.SerialAMPacket -> Serial;
  PCConnectionM.SerialSend -> Serial.AMSend;
  PCConnectionM.SerialReceive -> Serial.Receive;

//  FlashStorageImplM.BlockRead -> BlockStorage;
//  FlashStorageImplM.BlockWrite -> BlockStorage;
//  FlashStorageImplM.Leds -> LedsC;
  
  ProgramM.Boot -> MainC;
  ProgramM.Leds -> LedsC;
  ProgramM.PCConnection -> PCConnectionM;
  ProgramM.Timer -> Timer0;
  //ProgramM.FlashStorage -> FlashStorageImplM;
}