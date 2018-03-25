#include <Timer.h>
#include "ReceivePackage.h"
#include "StorageVolumes.h"

configuration pushImageToMoteC{
}
implementation{
   components MainC;
   components LedsC;
   components pushImageToMoteP as App;
   components SerialActiveMessageC as Serial;
   components new BlockStorageC(VOLUME_BLOCKTEST) as BlockStorage;
 
   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.SerialControl -> Serial;
   App.UartReceive -> Serial.Receive;
   App.BlockWrite -> BlockStorage;	
}