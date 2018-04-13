module ProgramM{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as Timer;
  }
}
implementation{

  event void Boot.booted(){
    // TODO Auto-generated method stub
  }

  event void Timer.fired(){
    // TODO Auto-generated method stub
  }
}