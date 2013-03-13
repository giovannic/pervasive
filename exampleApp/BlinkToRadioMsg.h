#ifndef BLINK_TO_RADIO_MSG_H
#define BLINK_TO_RADIO_MSG_H

typedef nx_struct BlinkToRadioMsg {
  nx_uint16_t nodeid;
  nx_int16_t temp;
  nx_int16_t light;
  nx_bool fire;
} BlinkToRadioMsg;

#endif
