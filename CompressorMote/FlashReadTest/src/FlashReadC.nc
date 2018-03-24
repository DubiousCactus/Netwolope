#include <Timer.h>
#include "FlashRead.h"
#include "StorageVolumes.h"

configuration FlashReadC{
	
}
implementation{
  components MainC;
  components LedsC;
  components FlashReadP;
  components new BlockStorageC(VOLUME_BLOCKTEST) as BlockStorage;   
  components SerialActiveMessageC as Serial;
  components new TimerMilliC() as Timer0;
    
  FlashReadP.Boot -> MainC;
  FlashReadP.Leds -> LedsC;
  FlashReadP.BlockRead -> BlockStorage;
  FlashReadP.SerialControl -> Serial;
  FlashReadP.UartSend -> Serial.AMSend;   
  FlashReadP.SerialPacket -> Serial;
  FlashReadP.SerialAMPacket -> Serial;  
  FlashReadP.Timer0 -> Timer0;	

}
