#include "RadioHeader.h"
interface RadioReceiver{
command void start();
event void receivedData(nx_uint8_t * data, nx_uint8_t size);
event void readyForReceive();
}
