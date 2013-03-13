//## Starting code for tutorial 2 of the wireless sensor network
//## programing module of the pervasive systems course.

#include "Timer.h"
#include "Blink.h"
#include "BlinkToRadioMsg.h"
#include "limits.h"

module BlinkC
{
	uses {
		interface Timer<TMilli> as SensorTimer;
		interface Timer<TMilli> as SendLedTimer;
		interface Timer<TMilli> as ReceiveLedTimer;
		interface Leds;
		interface Boot;
		interface Read<uint16_t> as Temp_Sensor;
		interface Read<uint16_t> as Light_Sensor;

		interface SplitControl as AMControl;
		interface Receive; 
		interface TimeSyncAMSend<TMilli,uint32_t>;
		interface TimeSyncPacket<TMilli,uint32_t>;
  	
		interface LocalTime<TMilli>;
	}
}
implementation
{
  bool busy = FALSE;
  message_t pkt;
  temp_state temp;
  light_state light;
  bool fire = FALSE;

  event void Boot.booted()
  {
    init_temp(&temp);
    init_light(&light);
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

  task void send() {
      if (!busy) {
        BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call TimeSyncAMSend.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
        btrpkt->nodeid = TOS_NODE_ID;
        btrpkt->temp = latest_temp(&temp);
        btrpkt->light = light.value;
        btrpkt->fire = fire;

        if (call TimeSyncAMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg), call LocalTime.get()) == SUCCESS) {
          busy = TRUE;
        }
      } else {
        post send();
      }
  }

  task void recent_temp_increase() 
  {
    int16_t max_val = -32678;
    int i, check_index, readings;

    readings = ( !temp.full ) ? temp.index : TEMP_MAX;

    for( i = 0; i < readings; i++ ) {

      check_index = (temp.index - i) % readings;

      if( check_index < 0 ) {
        check_index += readings;
      }

      if( temp.values[check_index] > max_val ) {
        max_val = temp.values[check_index];
      }
      else if( (max_val - temp.values[check_index]) >= 20 ) {
        fire = TRUE;
        break;
      }

    }
  } 


  task void check_fire()
  {
    //check for fire
    if (!light.neighbour_light)
    {
      post recent_temp_increase(); 
    }
    light.neighbour_light = FALSE;
  }

  event void TimeSyncAMSend.sendDone(message_t *msg, error_t err)
  {
    if (&pkt == msg) {
      busy = FALSE;
      temp.value_set = light.value_set = FALSE;
    }
  }



  task void check_send()
  {
    if (temp.value_set && light.value_set) {
      post send();
      post check_fire();
    }
  }
  
  event void Temp_Sensor.readDone(error_t result, uint16_t data) {
    temp_push(&temp, data);
    temp.value_set = TRUE;
    post check_send();
  }

  event void Light_Sensor.readDone(error_t result, uint16_t data) {
    light.value = data;
    light.value_set = TRUE;
    post check_send();
  }
  
  event void SendLedTimer.fired()
  {
    call Leds.led2Off();
  }
  
  task void flash_yellow()
  {
    call Leds.led2On();
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
    call Leds.led1On();
    call ReceiveLedTimer.startOneShot(LED_FLASH_PERIOD);
  }

  event void ReceiveLedTimer.fired()
  {
    call Leds.led1Off();
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    if (len == sizeof(BlinkToRadioMsg))
    {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*) payload;
      if (btrpkt->nodeid >= 33 && btrpkt->nodeid <= 36 && (call TimeSyncPacket.isValid(msg)))
      {
        // The time when the other gut did the temperature reading
        uint32_t otherRead = call TimeSyncPacket.eventTime(msg);
        uint32_t previousRead = call SensorTimer.gett0();
  
        // Fireflies protocol
        uint32_t shift = 0;
        uint32_t dist = (otherRead - previousRead) % call SensorTimer.getdt();
        if (otherRead > previousRead && dist > (call SensorTimer.getdt()) / 2)
        {
          shift = (call SensorTimer.getdt() - dist) / 4;
        }
        call SensorTimer.startPeriodicAt(previousRead - shift, call SensorTimer.getdt());

        if (btrpkt->light > 100) {
          post flash_green();
        } else {
          light.neighbour_light = TRUE; 
        }
      }
    }
    return msg;
  }

}
