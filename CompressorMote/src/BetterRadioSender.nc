#include "BetterRadioSender.h"

interface BetterRadioSender {
  command void init();
  command void sendFileBegin(uint32_t uncompressedSize, uint8_t compressionType);
  command void sendPartialData();
  command void sendEOF();

  /**
   * Determines whether the buffer has data that can be
   * sent over the radio.
   */
  command bool canSend();

  /**
   * Determines whether the buffer has enough data
   * to send a packet with 64 bytes in the payload.
   */
  command bool canSendFullPacket();

  event void initDone();
  event void sendDone();
  event void fileBeginAcknowledged();
  event void error(RadioSenderError error);
}

