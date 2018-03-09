#include <Timer.h>
 #include "BlinkToRadio.h"
 
 configuration BlinkToRadioAppC {
 }
 implementation {
   components MainC;
   components LedsC;
   components BlinkToRadioC as App;
   components SerialActiveMessageC as Serial;
 
   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.SerialControl -> Serial;
   App.UartReceive -> Serial.Receive;
 }
