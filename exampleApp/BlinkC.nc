//## Starting code for tutorial 2 of the wireless sensor network
//## programing module of the pervasive systems course.

#include "Timer.h"
#include "BlinkToRadioMsg.h"

module BlinkC
{
  uses interface Timer<TMilli> as SensorTimer;
  uses interface Timer<TMilli> as LedTimer;
  uses interface Timer<TMilli> as RecievedTimer;
  uses interface Leds;
  uses interface Boot;
  uses interface Read<uint16_t> as Temp_Sensor;

  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;

  uses interface Recieve; 
}
implementation
{

  typedef nx_struct BlinkToRadioMsg {
    nx_uint16_t nodeid;
    nx_uint16_t temp;
  } BlinkToRadioMsg;

  bool busy = FALSE;
  message_t pkt;

  enum{
    SAMPLE_PERIOD = 1024,
    LED_FLASH_PERIOD = 50,
  };

  uint16_t temperature_value;

  event void Boot.booted()
  {
    temperature_value = 0;
    call AMControl.start();
  }

  event void SensorTimer.fired()
  {
    
    call Leds.led0Toggle();
    call Temp_Sensor.read();
    
  }

  event void RecievedTimer.fired()
  {
    
    call Leds.led2Toggle();
    
  }

  event void LedTimer.fired()
  {
    
    call Leds.led0Toggle();
  
  }

  event void AMSend.sendDone(message_t *msg, error_t err)
  {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

  event void AMControl.startDone(error_t err)
  {
    if (err == SUCCESS) {
      call SensorTimer.startPeriodic(SAMPLE_PERIOD);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err)
  {
    // TODO
  }

  /******** Sensor Sending code *******************/
  event void Temp_Sensor.readDone(error_t result, uint16_t data) {

    //flash yellow on sample done - works?
    call LedTimer.startOneShot(LED_FLASH_PERIOD);

    temperature_value = data;

    if (!busy) {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
      btrpkt->nodeid = TOS_NODE_ID;
      btrpkt->temp = temperature_value;
      if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
      }
    }

  }

  /******** Sensor Recieve code *******************/
  event void Recieve.receive(message_t* msg, void* payload, uint8_t len) {
    if (len == sizeof(BlinkToRadioMsg)) {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
      call Leds.set(btrpkt->counter);
    }
    return msg;
  }

}
