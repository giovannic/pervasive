#ifndef BLINK_H
#define BLINK_H

enum {
  TIMER_PERIOD_MILLI = 1000,
  SAMPLE_PERIOD = 1024,
  LED_FLASH_PERIOD = 50,
  DARK_FLASH_PERIOD = 20,
  SENSORS = 3,
  TEMP_MAX = 30
};

typedef struct light_state{
  uint16_t value;
  bool value_set;
  bool neighbour_light;
} light_state;

typedef struct temp_state{
  int16_t values[TEMP_MAX];
  float avgs[TEMP_MAX];
  uint8_t index;
  bool value_set;
  bool full;
} temp_state;

void init_light(light_state* l){
  l->value_set = FALSE;
  l->neighbour_light = FALSE;
}

void init_temp(temp_state* t){
  memset(t->values,0,TEMP_MAX * sizeof(*t->values));
  memset(t->avgs,0,TEMP_MAX * sizeof(*t->avgs));
  //hack to start at 0
  t->index = TEMP_MAX - 1;
  t->value_set = FALSE;
  t->full = FALSE;
}

uint16_t latest_temp(temp_state* t){
  return t->values[t->index];
}

void temp_push(temp_state* t, uint16_t data){
  //add data
  uint16_t overwritten;
  float last_avg = t->avgs[t->index]; 
  t->index = (t->index + 1) % TEMP_MAX; 
  overwritten = t->values[t->index];
  t->values[t->index] = data;

  //update average
  if (t->full)
  {
    t->avgs[t->index] = last_avg - (float)overwritten/TEMP_MAX + (float)data/TEMP_MAX;
  } else {
    t->avgs[t->index] = (last_avg*(t->index - 1) + (float)data)/t->index;
  }
 
  //update full
  if (t->index == TEMP_MAX - 1)
  {
    t->full = TRUE;
  }
}
#endif
