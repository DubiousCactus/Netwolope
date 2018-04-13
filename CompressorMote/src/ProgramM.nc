module ProgramM{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as Timer;
    interface IDataPackageCommunication as RadioSender;
    interface PCFileReceiver;
  }
}
implementation{
  event void Boot.booted(){
    call RadioSender.start(1);
  }

  event void RadioSender.readyToSend(){
    call PCFileReceiver.init();
  }
  
  event void PCFileReceiver.receivedData(uint8_t *data, uint16_t length){
    call RadioSender.send(0, 0, (nx_uint8_t *)data, (nx_uint8_t)length);
  }
  
  event void RadioSender.sendDone(){
    call PCFileReceiver.receiveMore();
  }
  
  event void PCFileReceiver.fileEnd(){
    call Leds.led1On();
  }

  event void PCFileReceiver.initDone(){ }
  
  event void Timer.fired(){ }

  event void RadioSender.receivedData(nx_uint8_t *data, nx_uint8_t size){ }

  event void PCFileReceiver.fileBegin(uint32_t totalLength){}


  event void PCFileReceiver.error(PCFileSenderError error){
    call Leds.led0On();
  }
}