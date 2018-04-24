module ErrorIndicatorM {
  provides interface ErrorIndicator;
  uses {
    interface Timer<TMilli> as BlinkTimer;
    interface Leds;
  }
}
implementation {
  uint8_t blinkTimes;
  uint8_t currentIteration;
  bool pause;
  
  command void ErrorIndicator.blinkRed(uint8_t number) {
    blinkTimes = number;
    pause = FALSE;
    call Leds.led0Off();
    call BlinkTimer.startPeriodic(300);
  }

  event void BlinkTimer.fired() {
    currentIteration++;
    if (pause == FALSE) {
      call Leds.led0Toggle();
      if (currentIteration / 2 == blinkTimes) {
        pause = TRUE;
        currentIteration = 0;
      }
    } else {
      if (currentIteration > 6) {
        pause = FALSE;
        currentIteration = 0;
      }
    }
  }
}
