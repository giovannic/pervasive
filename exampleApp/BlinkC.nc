//## Starting code for tutorial 2 of the wireless sensor network
//## programing module of the pervasive systems course.

#include "Timer.h"
#include "BlinkToRadioMsg.h"

module BlinkC
{
  uses interface Timer<TMilli> as SensorTimer;
  uses interface Timer<TMilli> as SendLedTimer;
  uses interface Timer<TMilli> as ReceiveLedTimer;
  uses interface Leds;
  uses interface Boot;
  uses interface Read<uint16_t> as Temp_Sensor;

  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;

  uses interface Receive; 
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
    LED_FLASH_PERIOD = 50
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

  event void SendLedTimer.fired()
  {
    call Leds.led1Off();
  }

  task void flash_yellow()
  {
    call Leds.led1On();
    call SendLedTimer.startOneShot(LED_FLASH_PERIOD);
  }

  event void AMSend.sendDone(message_t *msg, error_t err)
  {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

  event void Temp_Sensor.readDone(error_t result, uint16_t data) {

    //flash yellow on sample done - works?
    post flash_yellow();

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

  task void flash_green()
  {
    call Leds.led2On();
    call ReceiveLedTimer.startOneShot(LED_FLASH_PERIOD);
  }

  event void ReceiveLedTimer.fired()
  {
    call Leds.led2Off();
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    if (len == sizeof(BlinkToRadioMsg)) {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
      if (btrpkt->temp > 100)
        post flash_green();
    }
    return msg;
  }

}
