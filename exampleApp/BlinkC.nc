//## Starting code for tutorial 2 of the wireless sensor network
//## programing module of the pervasive systems course.

#include "Timer.h"
#include "Blink.h"
#include "BlinkToRadioMsg.h"

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

  uint16_t temp_values[TEMP_MAX];
  uint8_t temp_index = TEMP_MAX - 1; // This is a complete hack to make sure that temp_index is always pointing at curr index not curr index +1
  bool temp_set = FALSE;

  uint16_t light_value;
  bool light_set = FALSE;
  float avg_temp;
  int num_temp_readings = 0;
  
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

  event void TimeSyncAMSend.sendDone(message_t *msg, error_t err)
  {
    if (&pkt == msg) {
      busy = FALSE;
      //call TimeSyncPacket.clear(&pkt);
      temp_set = light_set = FALSE;
    }
  }

  task void check_send()
  {
    if (temp_set && light_set) {
      if (!busy) {
        BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call TimeSyncAMSend.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
        btrpkt->nodeid = TOS_NODE_ID;
        btrpkt->temp = temp_values[temp_index];
        btrpkt->light = light_value;

        if (call TimeSyncAMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg), call LocalTime.get()) == SUCCESS) {
          busy = TRUE;
        }
      } else {
        post check_send();
      }
    }

  }
  
  event void Temp_Sensor.readDone(error_t result, uint16_t data) {
    temp_values[temp_index] = data; 
    temp_set = TRUE;
    temp_index = (temp_index + 1) % TEMP_MAX;
    num_temp_readings++;
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

  task void avg_temperature()
  {
    uint16_t sum = 0;
    int i, readings;

    readings = ( num_temp_readings < TEMP_MAX ) ? temp_index : TEMP_MAX;

    for( i = 0; i < readings; i++ ) {
      sum += temp_values[i];
    }

    avg_temp = (float) sum / readings;
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
		if (call TimeSyncPacket.isValid(msg))
		{
			// The time when the other gut did the temperature reading
			uint32_t otherRead = call TimeSyncPacket.eventTime(msg);
			uint32_t previousRead = call SensorTimer.gett0();

			// Fireflies protocol
			uint32_t shift = 0;
      uint32_5 dist = (otherRead - previousRead) % call SensorTimer.getdt()
			if (otherRead < previousRead && dist > (call SensorTimer.getdt()) / 2) {
				  shift = (call SensorTimer.getdt() - dist) / 4;
			}
			call SensorTimer.startPeriodicAt(previousRead - shift, call SensorTimer.getdt());
			
			if (len == sizeof(BlinkToRadioMsg)) {
				BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
				if (btrpkt->temp > 100)
					post flash_green();
			}
		}
    return msg;
  }

}
