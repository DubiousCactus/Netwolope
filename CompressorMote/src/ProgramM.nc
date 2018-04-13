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
    call RadioSender.send(0, 0, data, length);
  }
  
  event void RadioSender.sendDone(){
    call PCFileReceiver.receiveMore();
  }

  event void PCFileReceiver.initDone(){ }
  
  event void Timer.fired(){ }

  event void RadioSender.receivedData(uint8_t *data, u_int8_t size){ }

  event void PCFileReceiver.fileBegin(uint32_t totalLength){}

  event void PCFileReceiver.fileEnd(){}

  event void PCFileReceiver.error(PCFileSenderError error){
    call Leds.led0On();
  }
}