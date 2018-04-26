interface ErrorIndicator{
  /**
   * Makes the red LED blink a number of times.
   * 
   * @param numberOfBlinks  The number of times to blink the red LED.
   */
  command void blinkRed(uint8_t numberOfBlinks);
}