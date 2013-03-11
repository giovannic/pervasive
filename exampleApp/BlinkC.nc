//## Starting code for tutorial 2 of the wireless sensor network
//## programing module of the pervasive systems course.

#include "Timer.h"
#include "Blink.h"
#include "BlinkToRadioMsg.h"

module BlinkC
{
  uses interface Timer<TMilli> as SensorTimer;
  uses interface Timer<TMilli> as SendLedTimer;
  uses interface Timer<TMilli> as ReceiveLedTimer;
  uses interface Leds;
  uses interface Boot;
  uses interface Read<uint16_t> as Temp_Sensor;
  uses interface Read<uint16_t> as Light_Sensor;

  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;

  uses interface Receive; 
}
implementation
{
  bool busy = FALSE;
  message_t pkt;

  uint16_t temp_values[TEMP_MAX];
  uint8_t temp_index = 0;
  bool temp_set = FALSE;

  uint16_t light_value;
  bool light_set = FALSE;
  
  event void Boot.booted()
  {
    call AMControl.start();
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

  event void AMSend.sendDone(message_t *msg, error_t err)
  {
    if (&pkt == msg) {
      busy = FALSE;
      call Packet.clear(&pkt);
      temp_set = light_set = FALSE;
    }
  }

  task void check_send()
  {
    if (temp_set && light_set) {
      if (!busy) {
        BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
        btrpkt->nodeid = TOS_NODE_ID;
        btrpkt->temp = temp_values[temp_index];
        btrpkt->light = light_value;
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
          busy = TRUE;
        }
      } else {
        post check_send();
      }
    }

  }
  
  event void Temp_Sensor.readDone(error_t result, uint16_t data) {
    temp_index = (temp_index + 1) % TEMP_MAX;
    temp_values[temp_index] = data; 
    temp_set = TRUE;
    post check_send();
  }

  event void Light_Sensor.readDone(error_t result, uint16_t data) {
    light_value = data;
    light_set = TRUE;
    post check_send();
  }
  
  event void SendLedTimer.fired()
  {
    call Leds.led1Off();
  }
  
  task void flash_yellow()
  {
    call Leds.led1On();
    call SendLedTimer.startOneShot(LED_FLASH_PERIOD);
  }
  
  event void SensorTimer.fired()
  {
    post flash_yellow();
    call Temp_Sensor.read();
    call Light_Sensor.read();
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
