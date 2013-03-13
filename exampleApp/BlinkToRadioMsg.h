#ifndef BLINK_TO_RADIO_MSG_H
#define BLINK_TO_RADIO_MSG_H
enum{
  AM_BLINKTORADIOMSG = 6,
};

typedef nx_struct BlinkToRadioMsg {
  nx_uint16_t nodeid;
  nx_uint16_t temp;
  nx_uint16_t light;
  nx_bool fire;
} BlinkToRadioMsg;

#endif
