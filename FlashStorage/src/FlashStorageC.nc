#include "StorageVolumes.h"


configuration FlashStorageC{
}
implementation{
  components MainC;
  components LedsC;
  components FlashStorageM;
  components new BlockStorageC(VOLUME_BLOCKTEST) as BlockStorage;
  
  FlashStorageM.Boot -> MainC;
  FlashStorageM.Leds -> LedsC;
  FlashStorageM.BlockRead -> BlockStorage;
  FlashStorageM.BlockWrite -> BlockStorage;
}