#include "StorageVolumes.h"

configuration ProgramC{
}
implementation{
  components MainC;
  components LedsC;
  components ProgramM;
  components SerialActiveMessageC as Serial;
  components ActiveMessageC as Radio;
  
  components new BlockStorageC(VOLUME_BLOCKTEST) as BlockStorage;
  components new TimerMilliC() as Timer0;
  components PCFileReceiverM;
//  components RadioSenderM;
  components RadioSender2M;
  components NoCompressionM;
  components ErrorIndicatorM;
//  components FlashStorageM;


  PCFileReceiverM.SerialControl -> Serial;
  PCFileReceiverM.SerialPacket -> Serial;
  PCFileReceiverM.SerialAMPacket -> Serial;
  PCFileReceiverM.SerialSend -> Serial.AMSend;
  PCFileReceiverM.SerialReceive -> Serial.Receive;

//  FlashStorageM.BlockRead -> BlockStorage;
//  FlashStorageM.BlockWrite -> BlockStorage;
//  FlashStorageM.Leds -> LedsC;

//  RadioSenderM.Packet -> AMSender;
//  RadioSenderM.AMPacket -> AMSender;
//  RadioSenderM.AMSend -> AMSender;
//  RadioSenderM.Receive -> AMReceiver;
//  RadioSenderM.AMControl -> Radio;
//  RadioSenderM.Leds -> LedsC;

  RadioSender2M.Packet -> Radio;
  RadioSender2M.AMPacket -> Radio;
  RadioSender2M.RadioSend -> Radio.AMSend;
  RadioSender2M.RadioReceive -> Radio.Receive;
  RadioSender2M.RadioControl -> Radio;

  ErrorIndicatorM.BlinkTimer -> Timer0;
  ErrorIndicatorM.Leds -> LedsC;
  
  ProgramM.Boot -> MainC;
  ProgramM.Leds -> LedsC;
  ProgramM.RadioSender -> RadioSender2M;
  ProgramM.PCFileReceiver -> PCFileReceiverM;
  ProgramM.Compressor -> NoCompressionM;
  ProgramM.ErrorIndicator -> ErrorIndicatorM;
//  ProgramM.FlashStorage -> FlashStorageM;
}
