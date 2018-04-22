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
  components RadioSenderM;
  components NoCompressionM;
  components ErrorIndicatorM;
  components new CircularBufferM(1024) as UncompressedBuffer;
  components new CircularBufferM(1024) as CompressedBuffer;
//  components FlashStorageM;

  PCFileReceiverM.SerialControl -> Serial;
  PCFileReceiverM.SerialPacket -> Serial;
  PCFileReceiverM.SerialAMPacket -> Serial;
  PCFileReceiverM.SerialSend -> Serial.AMSend;
  PCFileReceiverM.SerialReceive -> Serial.Receive;
  PCFileReceiverM.Writer -> UncompressedBuffer;
  
  NoCompressionM.InBuffer -> UncompressedBuffer;
  NoCompressionM.OutBuffer -> CompressedBuffer;

//  FlashStorageM.BlockRead -> BlockStorage;
//  FlashStorageM.BlockWrite -> BlockStorage;
//  FlashStorageM.Leds -> LedsC;

  RadioSenderM.Packet -> Radio;
  RadioSenderM.AMPacket -> Radio;
  RadioSenderM.RadioSend -> Radio.AMSend;
  RadioSenderM.RadioReceive -> Radio.Receive;
  RadioSenderM.RadioControl -> Radio;
  RadioSenderM.Reader -> CompressedBuffer;

  ErrorIndicatorM.BlinkTimer -> Timer0;
  ErrorIndicatorM.Leds -> LedsC;
  
  ProgramM.Boot -> MainC;
  ProgramM.Leds -> LedsC;
  ProgramM.RadioSender -> RadioSenderM;
  ProgramM.PCFileReceiver -> PCFileReceiverM;
  ProgramM.Compressor -> NoCompressionM;
  ProgramM.ErrorIndicator -> ErrorIndicatorM;
}
