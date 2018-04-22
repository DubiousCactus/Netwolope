#include "StorageVolumes.h"
//#include "printf.h"

#define COMPRESSION_RUN_LENGTH

configuration FlashTestC{
}
implementation{
  components MainC;
  components LedsC;
  components FlashTestM;
  components SerialActiveMessageC as Serial;
  components ActiveMessageC as Radio;
  
  components new BlockStorageC(VOLUME_BLOCKTEST) as BlockStorage;
  components new TimerMilliC() as Timer0;
  components PCFileReceiverM;
  components RadioSenderM;
  
  components ErrorIndicatorM;
  components new CircularBufferM(1024) as UncompressedBuffer;
  components new CircularBufferM(1024) as CompressedBuffer;
  components FlashStorageM;

  PCFileReceiverM.SerialControl -> Serial;
  PCFileReceiverM.SerialPacket -> Serial;
  PCFileReceiverM.SerialAMPacket -> Serial;
  PCFileReceiverM.SerialSend -> Serial.AMSend;
  PCFileReceiverM.SerialReceive -> Serial.Receive;
  PCFileReceiverM.Writer -> UncompressedBuffer;
  
  FlashStorageM.ReadBuffer -> UncompressedBuffer;
  FlashStorageM.WriteBuffer -> UncompressedBuffer;
  FlashStorageM.BlockRead -> BlockStorage;
  FlashStorageM.BlockWrite -> BlockStorage;

  RadioSenderM.Packet -> Radio;
  RadioSenderM.AMPacket -> Radio;
  RadioSenderM.RadioSend -> Radio.AMSend;
  RadioSenderM.RadioReceive -> Radio.Receive;
  RadioSenderM.RadioControl -> Radio;
  RadioSenderM.Reader -> CompressedBuffer;

  ErrorIndicatorM.BlinkTimer -> Timer0;
  ErrorIndicatorM.Leds -> LedsC;
  
  FlashTestM.Boot -> MainC;
  FlashTestM.Leds -> LedsC;
  FlashTestM.RadioSender -> RadioSenderM;
  FlashTestM.PCFileReceiver -> PCFileReceiverM;
  FlashTestM.ErrorIndicator -> ErrorIndicatorM;
  FlashTestM.FlashReader -> FlashStorageM;
  FlashTestM.FlashWriter -> FlashStorageM;
  FlashTestM.FlashError -> FlashStorageM;
  FlashTestM.UncompressedBufferReader -> UncompressedBuffer;
  FlashTestM.UncompressedBufferWriter -> UncompressedBuffer;
  
  
  #ifdef COMPRESSION_NONE
  components NoCompressionM;
  
  NoCompressionM.InBuffer -> UncompressedBuffer;
  NoCompressionM.OutBuffer -> CompressedBuffer;
  
  FlashTestM.Compressor -> NoCompressionM;
  #endif
  
  #ifdef COMPRESSION_RUN_LENGTH
  components RunLengthEncoderM;
  
  RunLengthEncoderM.InBuffer -> UncompressedBuffer;
  RunLengthEncoderM.OutBuffer -> CompressedBuffer;
  
  FlashTestM.Compressor -> RunLengthEncoderM;
  #endif
}
