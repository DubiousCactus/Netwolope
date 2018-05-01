#define NEW_PRINTF_SEMANTICS

#include "printf.h"
#include "StorageVolumes.h"

#define COMPRESSION_RUN_LENGTH

configuration ProgramC {
}
implementation {
  components MainC;
  components PrintfC;
  components SerialStartC;
  components LedsC;
  components ProgramM;
  components SerialActiveMessageC as Serial;
  components new TimerMilliC() as Timer;
  components new TimerMilliC() as DebugTimer;
  
  components ActiveMessageC as Radio;
  
  components new BlockStorageC(VOLUME_BLOCKTEST) as BlockStorage;
  components PCFileReceiverM;
  components RadioSenderM;
  
  components ErrorIndicatorM;
  components new CircularBufferM(1024) as UncompressedBuffer;
  components new CircularBufferM(2048) as CompressedBuffer;
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

  ErrorIndicatorM.BlinkTimer -> Timer;
  ErrorIndicatorM.Leds -> LedsC;
  
  ProgramM.Boot -> MainC;
  ProgramM.Leds -> LedsC;
  ProgramM.RadioSender -> RadioSenderM;
  ProgramM.PCFileReceiver -> PCFileReceiverM;
  ProgramM.ErrorIndicator -> ErrorIndicatorM;
  ProgramM.FlashReader -> FlashStorageM;
  ProgramM.FlashWriter -> FlashStorageM;
  ProgramM.FlashError -> FlashStorageM;
  ProgramM.UncompressedBufferReader -> UncompressedBuffer;
  ProgramM.UncompressedBufferWriter -> UncompressedBuffer;
 
  ProgramM.Timer -> DebugTimer; 
  
  #if defined(COMPRESSION_NONE)

  components NoCompressionM;
  NoCompressionM.InBuffer -> UncompressedBuffer;
  NoCompressionM.OutBuffer -> CompressedBuffer;
  ProgramM.Compressor -> NoCompressionM;

  #elif defined(COMPRESSION_RUN_LENGTH)

  components RunLengthEncoderM;
  RunLengthEncoderM.InBuffer -> UncompressedBuffer;
  RunLengthEncoderM.OutBuffer -> CompressedBuffer;
  ProgramM.Compressor -> RunLengthEncoderM;

  #elif defined(COMPRESSION_ROSS)

  components RossCompressionM;
  RossCompressionM.InBuffer -> UncompressedBuffer;
  RossCompressionM.OutBuffer -> CompressedBuffer;
  ProgramM.Compressor -> RossCompressionM;

  #endif
}
