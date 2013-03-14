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
  uint16_t values[TEMP_MAX];
  uint8_t index;
  bool value_set;
  bool full;
} temp_state;

typedef struct neighbours{
  uint16_t light[SENSORS];
  uint16_t temp[SENSORS];
} neighbours;

void init_light(light_state* l){
  l->value_set = FALSE;
  l->neighbour_light = FALSE;
}

void init_temp(temp_state* t){
  memset(t->values,0,TEMP_MAX * sizeof(*t->values));
  //hack to start at 0
  t->index = TEMP_MAX - 1;
  t->value_set = FALSE;
  t->full = FALSE;
}

void init_neighbours(neighbours* n) {
  memset(n->light,0,SENSORS * sizeof(*n->light));
  memset(n->temp,0,SENSORS * sizeof(*n->temp));
}

uint16_t latest_temp(temp_state* t){
  return t->values[t->index];
}

void temp_push(temp_state* t, uint16_t data){
  //add data
  t->index = (t->index + 1) % TEMP_MAX; 
  t->values[t->index] = data;
 
  //update full
  if (t->index == TEMP_MAX - 1)
  {
    t->full = TRUE;
  }
}

void neighbour_store(neighbours* n, uint16_t id, uint16_t temp, uint16_t light){
  n->temp[id - 33] = temp;
  n->light[id - 33] = light;
} 

#endif
