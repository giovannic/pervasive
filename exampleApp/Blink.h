#ifndef BLINK_H
#define BLINK_H

enum {
  AM_BLINKTORADIOMSG = 6,
  TIMER_PERIOD_MILLI = 1000,
  SAMPLE_PERIOD = 1024,
  LED_FLASH_PERIOD = 50,
  SENSORS = 3,
  TEMP_MAX = 30
};

typedef struct light_state{
  uint16_t value;
  bool value_set;
  bool neighbour_light;
} light_state;

typedef struct temp_state{
  uint16_t values[TEMP_MAX];
  uint8_t index;
  bool value_set;
} temp_state;

void init_light(light_state* l){
  l->value_set = FALSE;
  l->neighbour_light = FALSE;
}

void init_temp(temp_state* t){
  t->index = 0;
  t->value_set = FALSE;
}

uint16_t latest_temp(temp_state* t){
  return t->values[t->index];
}

void temp_push(temp_state* t, uint16_t data){
  t->index = (t->index + 1) % TEMP_MAX;
  t->values[t->index] = data; 
}
#endif
