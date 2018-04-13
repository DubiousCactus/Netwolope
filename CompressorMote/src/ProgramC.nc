#include "StorageVolumes.h"

configuration ProgramC{
}
implementation{
  components MainC;
  components LedsC;
  components ProgramM;
  components SerialActiveMessageC as Serial;
  
  components ActiveMessageC as Radio;
  components new AMSenderC(6) as AMSender;
  components new AMReceiverC(6) as AMReceiver;
  
  components new BlockStorageC(VOLUME_BLOCKTEST) as BlockStorage;
  components new TimerMilliC() as Timer0;
  components PCFileReceiverM;
  components DataPackageCommunication;
  
//
//  components PCFileReceiverM;
//  components FlashStorageM;
//
  PCFileReceiverM.SerialControl -> Serial;
  PCFileReceiverM.SerialPacket -> Serial;
  PCFileReceiverM.SerialAMPacket -> Serial;
  PCFileReceiverM.SerialSend -> Serial.AMSend;
  PCFileReceiverM.SerialReceive -> Serial.Receive;
//
//  FlashStorageM.BlockRead -> BlockStorage;
//  FlashStorageM.BlockWrite -> BlockStorage;
//  FlashStorageM.Leds -> LedsC;

  DataPackageCommunication.Packet -> AMSender;
  DataPackageCommunication.AMPacket -> AMSender;
  DataPackageCommunication.AMSend -> AMSender;
  DataPackageCommunication.Receive -> AMReceiver;
  DataPackageCommunication.AMControl -> Radio;
  DataPackageCommunication.Leds -> LedsC;
  
  ProgramM.Boot -> MainC;
  ProgramM.Leds -> LedsC;
  ProgramM.Timer -> Timer0;
  ProgramM.RadioSender -> DataPackageCommunication;
  ProgramM.PCFileReceiver -> PCFileReceiverM;
//  ProgramM.FlashStorage -> FlashStorageM;
}
