#include "RadioHeader.h"
interface RadioSender{
	command void send(nx_uint8_t last, nx_uint8_t request, nx_uint8_t * data, nx_uint8_t size);
	command void start();
	event void readyToSend();
	event void sendDone();
}
