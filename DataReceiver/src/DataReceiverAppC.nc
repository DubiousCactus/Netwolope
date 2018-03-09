configuration DataReceiverAppC{
}
implementation{
   components MainC;
   components LedsC;
   components DataReceiverC as App;
   components SerialActiveMessageC as Serial;
 
   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.SerialControl -> Serial;
   App.UartReceive -> Serial.Receive;
}