#include "RadioHeader.h"

interface RadioSender {
  command void send(uint8_t last, uint8_t request, uint8_t * data, uint8_t size);
  command void start();
  event void readyToSend();
  event void sendDone();
}
