#include "DataPackageCommunication.h"
interface IDataPackageCommunication{
command void send(nx_uint8_t last, nx_uint8_t request, nx_uint8_t * data, nx_uint8_t size);
command void start(u_int8_t isSender);
event void readyToSend();
event void sendDone();
/*command void startlistening();
command void stopListening();*/
event void receivedData(nx_uint8_t * data, nx_uint8_t size);
}
