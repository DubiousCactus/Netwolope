#include "StorageVolumes.h"

configuration FlashStorageC{
}
implementation{
  components MainC;
  components LedsC;
  components FlashStorageM;
  components new BlockStorageC(VOLUME_BLOCKTEST) as BlockStorage;
  components FlashStorageImplM;
  
  FlashStorageImplM.BlockRead -> BlockStorage;
  FlashStorageImplM.BlockWrite -> BlockStorage;
  FlashStorageImplM.Leds -> LedsC;
  
  FlashStorageM.Boot -> MainC;
  FlashStorageM.Leds -> LedsC;
  FlashStorageM.FlashStorage -> FlashStorageImplM;
}