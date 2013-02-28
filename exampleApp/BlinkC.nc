#include "Timer.h"

uint32_t flashes = 0;

module BlinkC
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as FlashTimer;
  uses interface Leds;
  uses interface Boot;
  uses interface Read<uint16_t> as Temp_Sensor;
}
implementation
{
  event void Boot.booted()
  {
    call Timer0.startPeriodic( 5000 );
  }

  event void Timer0.fired()
  {
    call Temp_Sensor.read();
    call Leds.led0Toggle();
    call FlashTimer.startPeriodic(50);
  }

  task void processFlash()
  {
    if(flashes++ == 10)
    {
      call FlashTimer.stop();
      flashes = 0;
    }
  }

  event void FlashTimer.fired()
  {
    call Leds.led0Toggle();
    post processFlash();
  }

  event void Temp_Sensor.readDone(error_t result, uint16_t data)
  {

  }

}

